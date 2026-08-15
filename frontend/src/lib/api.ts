const API_URL =
  typeof window === "undefined"
    ? process.env.API_URL_INTERNAL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
    : process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

if (
  typeof window === "undefined" &&
  process.env.NODE_ENV === "production" &&
  /localhost|127\.0\.0\.1/.test(API_URL)
) {
  console.error(
    `[api] SSR is calling ${API_URL}. Set API_URL_INTERNAL (and NEXT_PUBLIC_API_URL) to the backend HTTPS URL on Railway, then redeploy the frontend.`,
  );
}

export type NationalIdType = "pan" | "other";

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: "customer" | "merchant" | "admin";
  is_active: boolean;
  avatar_url?: string | null;
  phone?: string | null;
  address_line1?: string | null;
  address_line2?: string | null;
  city?: string | null;
  state?: string | null;
  postal_code?: string | null;
  country?: string | null;
  national_id_type?: NationalIdType | null;
  national_id_number?: string | null;
  auth_provider?: string;
  totp_enabled?: boolean;
}

export type BusinessStatus = "pending" | "approved" | "rejected" | "suspended";

export interface Business {
  id: string;
  name: string;
  slug: string;
  description?: string;
  address: string;
  city: string;
  state?: string;
  postal_code?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  email?: string;
  website?: string;
  business_hours?: Record<string, unknown>;
  status?: BusinessStatus;
  average_rating: number;
  review_count: number;
  logo_url?: string;
  storefront_url?: string;
  categories?: { id?: string; name: string; slug: string }[];
  ai_merchant_summary?: string;
}

export interface BusinessCreateInput {
  name: string;
  description?: string;
  address: string;
  city: string;
  state?: string;
  postal_code?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  email?: string;
  website?: string;
  business_hours?: Record<string, unknown>;
  category_ids?: string[];
}

export interface BusinessUpdateInput {
  name?: string;
  description?: string;
  address?: string;
  city?: string;
  state?: string;
  postal_code?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  email?: string;
  website?: string;
  business_hours?: Record<string, unknown>;
  category_ids?: string[];
}

export interface NearbyRequest {
  lat: number;
  lng: number;
  radius_km?: number;
}

export interface GeocodeResponse {
  message: string;
  latitude?: number;
  longitude?: number;
  display_name?: string;
}

export interface MapsConfig {
  provider: string;
  api_key_configured: boolean;
  placeholder: boolean;
  tile_url?: string;
  attribution?: string;
}

export interface Review {
  id: string;
  business_id: string;
  rating: number;
  title?: string;
  body: string;
  like_count: number;
  created_at: string;
  author?: User;
  ai_analysis?: {
    sentiment?: string;
    summary?: string;
    suggested_response?: string;
  };
  reply?: { id: string; body: string; created_at: string } | null;
  photo_urls?: string[];
  business?: { id: string; name: string; slug: string; city?: string | null; status: BusinessStatus } | null;
}

export interface Photo {
  id: string;
  url: string;
  caption?: string;
  photo_type: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type?: string;
}

/** Password login may return full tokens or an MFA challenge / enrollment gate. */
export interface LoginResult {
  access_token?: string | null;
  refresh_token?: string | null;
  token_type?: string;
  mfa_required?: boolean;
  mfa_enrollment_required?: boolean;
  mfa_token?: string | null;
}

export interface TotpSetupResponse {
  otpauth_uri: string;
  secret: string;
  qr_svg: string;
}

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("access_token");
}

function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("refresh_token");
}

export function storeTokens(tokens: TokenResponse): void {
  localStorage.setItem("access_token", tokens.access_token);
  localStorage.setItem("refresh_token", tokens.refresh_token);
}

export function clearTokens(): void {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
}

/**
 * Revoke tokens server-side (best-effort), clear localStorage, hard-navigate
 * so ClientLayout remounts and bfcache cannot restore a signed-in shell.
 */
export async function performLogout(redirectTo = "/login"): Promise<void> {
  try {
    await auth.logout();
  } catch {
    // best-effort server revoke; local logout proceeds regardless
  }
  clearTokens();
  window.location.replace(redirectTo);
}

// Auth endpoints 401 on bad credentials, not an expired session -- retrying
// those through the refresh flow would just loop a login failure forever.
const NO_REFRESH_RETRY_PREFIXES = [
  "/api/v1/auth/login",
  "/api/v1/auth/register",
  "/api/v1/auth/refresh",
  "/api/v1/auth/google",
  "/api/v1/auth/mfa/",
];

// Concurrent 401s (a page firing several requests at once after the access
// token expires) must share one refresh call, not one each -- the second
// refresh would already be racing a rotated refresh_token from the first.
let refreshInFlight: Promise<TokenResponse> | null = null;

async function refreshTokens(): Promise<TokenResponse> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) throw new Error("No refresh token");
  const res = await fetch(`${API_URL}/api/v1/auth/refresh?refresh_token=${encodeURIComponent(refreshToken)}`, {
    method: "POST",
  });
  if (!res.ok) {
    clearTokens();
    throw new Error("Session expired");
  }
  const tokens: TokenResponse = await res.json();
  storeTokens(tokens);
  return tokens;
}

export async function apiFetch<T>(path: string, options: RequestInit = {}, _retried = false): Promise<T> {
  const token = getToken();
  const headers: HeadersInit = {
    ...(options.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
    ...(options.headers || {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };

  const method = (options.method || "GET").toUpperCase();
  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
    // Home/search SSR must not serve a stale empty list after seed or deploy.
    ...(typeof window === "undefined" && method === "GET" && options.cache === undefined
      ? { cache: "no-store" as RequestCache }
      : {}),
  });

  const canRetry = !_retried && getRefreshToken() && !NO_REFRESH_RETRY_PREFIXES.some((p) => path.startsWith(p));
  if (res.status === 401 && canRetry) {
    try {
      if (!refreshInFlight) {
        refreshInFlight = refreshTokens().finally(() => {
          refreshInFlight = null;
        });
      }
      await refreshInFlight;
      return apiFetch<T>(path, options, true);
    } catch {
      // Refresh itself failed (expired/invalid refresh token) -- fall through
      // and report the original 401 below rather than masking it.
    }
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail || "Request failed");
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const auth = {
  register: (data: { email: string; full_name: string; password: string; role: string }) =>
    apiFetch<User>("/api/v1/auth/register", { method: "POST", body: JSON.stringify(data) }),
  login: (data: { email: string; password: string }) =>
    apiFetch<LoginResult>("/api/v1/auth/login", { method: "POST", body: JSON.stringify(data) }),
  google: (data: { credential: string }) =>
    apiFetch<TokenResponse>("/api/v1/auth/google", { method: "POST", body: JSON.stringify(data) }),
  me: () => apiFetch<User>("/api/v1/auth/me"),
  updateMe: (data: UserProfileUpdateInput) =>
    apiFetch<User>("/api/v1/auth/me", { method: "PATCH", body: JSON.stringify(data) }),
  totpSetup: (mfaToken: string) =>
    apiFetch<TotpSetupResponse>("/api/v1/auth/mfa/totp/setup", {
      method: "POST",
      body: JSON.stringify({ mfa_token: mfaToken }),
    }),
  totpConfirm: (mfaToken: string, code: string) =>
    apiFetch<TokenResponse>("/api/v1/auth/mfa/totp/confirm", {
      method: "POST",
      body: JSON.stringify({ mfa_token: mfaToken, code }),
    }),
  totpVerify: (mfaToken: string, code: string) =>
    apiFetch<TokenResponse>("/api/v1/auth/mfa/totp/verify", {
      method: "POST",
      body: JSON.stringify({ mfa_token: mfaToken, code }),
    }),
  logout: () => {
    const refreshToken = getRefreshToken();
    return apiFetch<{ message: string }>("/api/v1/auth/logout", {
      method: "POST",
      body: JSON.stringify(refreshToken ? { refresh_token: refreshToken } : {}),
    });
  },
  /** Always resolves with the same generic confirmation, known or unknown address. */
  forgotPassword: (email: string) =>
    apiFetch<{ message: string }>("/api/v1/auth/forgot-password", {
      method: "POST",
      body: JSON.stringify({ email }),
    }),
  resetPassword: (token: string, newPassword: string) =>
    apiFetch<{ message: string }>("/api/v1/auth/reset-password", {
      method: "POST",
      body: JSON.stringify({ token, new_password: newPassword }),
    }),
};

export interface UserProfileUpdateInput {
  full_name?: string;
  avatar_url?: string | null;
  phone?: string | null;
  address_line1?: string | null;
  address_line2?: string | null;
  city?: string | null;
  state?: string | null;
  postal_code?: string | null;
  country?: string | null;
  national_id_type?: NationalIdType | null;
  national_id_number?: string | null;
}

export interface PublicPlatformStats {
  total_businesses: number;
  total_reviews: number;
  total_categories: number;
  total_cities: number;
}

export const businesses = {
  /** Public list; pass status_filter (e.g. "pending") and/or city for admin/filtered views. */
  list: (params?: { status_filter?: string; city?: string }) => {
    const qs = params ? new URLSearchParams(Object.entries(params).filter(([, v]) => v != null) as [string, string][]).toString() : "";
    return apiFetch<Business[]>(`/api/v1/businesses${qs ? `?${qs}` : ""}`);
  },
  get: (slug: string) => apiFetch<Business>(`/api/v1/businesses/${slug}`),
  mine: () => apiFetch<Business[]>("/api/v1/businesses/mine"),
  create: (data: BusinessCreateInput) =>
    apiFetch<Business>("/api/v1/businesses", { method: "POST", body: JSON.stringify(data) }),
  update: (id: string, data: BusinessUpdateInput) =>
    apiFetch<Business>(`/api/v1/businesses/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
  approve: (id: string) => apiFetch<Business>(`/api/v1/businesses/${id}/approve`, { method: "POST" }),
  suspend: (id: string) => apiFetch<{ message: string }>(`/api/v1/businesses/${id}/suspend`, { method: "POST" }),
  search: (params: Record<string, string>) => {
    const qs = new URLSearchParams(params).toString();
    return apiFetch<Business[]>(`/api/v1/search/businesses?${qs}`);
  },
  categoriesAll: () => apiFetch<Category[]>("/api/v1/businesses/categories/all"),
  /** Admin: create a category. 409 if name or slug already exists. */
  createCategory: (data: { name: string; slug: string; description?: string; icon?: string }) =>
    apiFetch<Category>("/api/v1/businesses/categories", { method: "POST", body: JSON.stringify(data) }),
  cities: () => apiFetch<string[]>("/api/v1/businesses/cities"),
  stats: () => apiFetch<PublicPlatformStats>("/api/v1/businesses/stats/summary"),
  /** Admin: browse businesses of every status, newest-registered first. */
  adminAll: (params?: { page?: number; page_size?: number }) => {
    const qs = params
      ? new URLSearchParams(
          Object.entries(params).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]),
        ).toString()
      : "";
    return apiFetch<Business[]>(`/api/v1/businesses/admin/all${qs ? `?${qs}` : ""}`);
  },
};

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
}

export const maps = {
  nearby: (data: NearbyRequest) =>
    apiFetch<Business[]>("/api/v1/maps/nearby", { method: "POST", body: JSON.stringify(data) }),
  geocode: (address: string) =>
    apiFetch<GeocodeResponse>(`/api/v1/maps/geocode?address=${encodeURIComponent(address)}`),
  config: () => apiFetch<MapsConfig>("/api/v1/maps/config"),
};

export const reviews = {
  list: (businessId: string) => apiFetch<Review[]>(`/api/v1/reviews/business/${businessId}`),
  create: (data: { business_id: string; rating: number; title?: string; body: string }) =>
    apiFetch<Review>("/api/v1/reviews", { method: "POST", body: JSON.stringify(data) }),
  like: (id: string) => apiFetch<{ message: string }>(`/api/v1/reviews/${id}/like`, { method: "POST" }),
  report: (id: string, reason: string) =>
    apiFetch<{ message: string }>(`/api/v1/reviews/${id}/report`, {
      method: "POST",
      body: JSON.stringify({ reason }),
    }),
  reply: (id: string, body: string) =>
    apiFetch<{ id: string; body: string; created_at: string }>(`/api/v1/reviews/${id}/reply`, {
      method: "POST",
      body: JSON.stringify({ body }),
    }),
  /** Admin: hide | restore | remove */
  moderate: (id: string, action: "hide" | "restore" | "remove") =>
    apiFetch<{ message: string }>(`/api/v1/reviews/${id}/moderate?action=${action}`, { method: "POST" }),
  /** Admin: list reviews flagged for moderation */
  reported: () => apiFetch<Review[]>("/api/v1/reviews/reported"),
  /** Admin: browse reviews across every business and status; pass business_id to scope to one business. */
  adminAll: (params?: { business_id?: string; page?: number; page_size?: number }) => {
    const qs = params
      ? new URLSearchParams(
          Object.entries(params).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]),
        ).toString()
      : "";
    return apiFetch<Review[]>(`/api/v1/reviews/admin/all${qs ? `?${qs}` : ""}`);
  },
};

export const photos = {
  listForBusiness: (businessId: string) => apiFetch<Photo[]>(`/api/v1/photos/business/${businessId}`),
  upload: (file: File, opts: { reviewId?: string; businessId?: string; photoType?: string; caption?: string }) => {
    const form = new FormData();
    form.append("file", file);
    if (opts.businessId) form.append("business_id", opts.businessId);
    if (opts.reviewId) form.append("review_id", opts.reviewId);
    if (opts.photoType) form.append("photo_type", opts.photoType);
    if (opts.caption) form.append("caption", opts.caption);
    return apiFetch<Photo>("/api/v1/photos/upload", { method: "POST", body: form });
  },
};

export type DashboardRange = "30" | "90" | "all";

export type AdminSeriesGranularity = "day" | "week";

export interface AdminSeriesBucket {
  bucket: string;
  count: number;
}

export interface PlatformAnalyticsSeries {
  granularity: AdminSeriesGranularity;
  days: number;
  series: Record<string, AdminSeriesBucket[]>;
}

export const dashboard = {
  merchant: (businessId: string, opts?: { range?: DashboardRange }) =>
    apiFetch<Record<string, unknown>>(
      `/api/v1/dashboard/merchant/${businessId}${opts?.range ? `?range=${opts.range}` : ""}`
    ),
  insights: (businessId: string) =>
    apiFetch<Record<string, unknown>>(`/api/v1/ai/businesses/${businessId}/insights`),
  refreshInsights: (businessId: string) =>
    apiFetch<Record<string, unknown>>(`/api/v1/ai/businesses/${businessId}/refresh`, { method: "POST" }),
  // Blob download (not JSON) -- can't route through apiFetch, but shares its
  // auth header so the export hits the same ownership check as the dashboard.
  reviewsCsv: async (businessId: string, opts?: { range?: DashboardRange }): Promise<Blob> => {
    const token = getToken();
    const qs = opts?.range ? `?range=${opts.range}` : "";
    const res = await fetch(`${API_URL}/api/v1/dashboard/merchant/${businessId}/reviews.csv${qs}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || "Export failed");
    }
    return res.blob();
  },
  /** Admin: platform time series (new users, approvals, reviews, reports) from stored timestamps. */
  adminSeries: (opts?: { granularity?: AdminSeriesGranularity; days?: number }) => {
    const params = new URLSearchParams();
    if (opts?.granularity) params.set("granularity", opts.granularity);
    if (opts?.days) params.set("days", String(opts.days));
    const qs = params.toString();
    return apiFetch<PlatformAnalyticsSeries>(`/api/v1/dashboard/admin/platform/series${qs ? `?${qs}` : ""}`);
  },
};

export const admin = {
  /** Admin: list users newest first; optional q substring on email/full_name. */
  users: (params?: { page?: number; page_size?: number; q?: string }) => {
    const qs = params
      ? new URLSearchParams(
          Object.entries(params).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]),
        ).toString()
      : "";
    return apiFetch<User[]>(`/api/v1/admin/users${qs ? `?${qs}` : ""}`);
  },
  suspendUser: (id: string) => apiFetch<User>(`/api/v1/admin/users/${id}/suspend`, { method: "POST" }),
  reactivateUser: (id: string) => apiFetch<User>(`/api/v1/admin/users/${id}/reactivate`, { method: "POST" }),
};

export interface Notification {
  id: string;
  type: string;
  title: string;
  message: string;
  is_read: boolean;
  extra_data?: Record<string, unknown> | null;
  created_at: string;
}

export const notifications = {
  list: (params?: { unreadOnly?: boolean }) =>
    apiFetch<Notification[]>(`/api/v1/notifications${params?.unreadOnly ? "?unread_only=true" : ""}`),
  markRead: (id: string) =>
    apiFetch<{ message: string }>(`/api/v1/notifications/${id}/read`, { method: "POST" }),
  markAllRead: () => apiFetch<{ message: string }>("/api/v1/notifications/read-all", { method: "POST" }),
};

export interface FavoriteToggleResponse {
  favorited: boolean;
  business_id: string;
}

export const favorites = {
  list: () => apiFetch<Business[]>("/api/v1/favorites"),
  add: (businessId: string) =>
    apiFetch<FavoriteToggleResponse>("/api/v1/favorites", {
      method: "POST",
      body: JSON.stringify({ business_id: businessId }),
    }),
  remove: (businessId: string) => apiFetch<void>(`/api/v1/favorites/${businessId}`, { method: "DELETE" }),
};

export { API_URL };
