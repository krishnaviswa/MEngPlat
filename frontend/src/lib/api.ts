const API_URL =
  typeof window === "undefined"
    ? process.env.API_URL_INTERNAL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
    : process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: "customer" | "merchant" | "admin";
  is_active: boolean;
}

export interface Business {
  id: string;
  name: string;
  slug: string;
  description?: string;
  address: string;
  city: string;
  average_rating: number;
  review_count: number;
  logo_url?: string;
  storefront_url?: string;
  categories?: { name: string; slug: string }[];
  ai_merchant_summary?: string;
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
}

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("access_token");
}

function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("refresh_token");
}

function storeTokens(tokens: TokenResponse): void {
  localStorage.setItem("access_token", tokens.access_token);
  localStorage.setItem("refresh_token", tokens.refresh_token);
}

function clearTokens(): void {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
}

// Auth endpoints 401 on bad credentials, not an expired session -- retrying
// those through the refresh flow would just loop a login failure forever.
const NO_REFRESH_RETRY_PREFIXES = ["/api/v1/auth/login", "/api/v1/auth/register", "/api/v1/auth/refresh", "/api/v1/auth/google"];

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

  const res = await fetch(`${API_URL}${path}`, { ...options, headers });

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
    apiFetch<TokenResponse>("/api/v1/auth/login", { method: "POST", body: JSON.stringify(data) }),
  google: (data: { credential: string }) =>
    apiFetch<TokenResponse>("/api/v1/auth/google", { method: "POST", body: JSON.stringify(data) }),
  me: () => apiFetch<User>("/api/v1/auth/me"),
  logout: () => apiFetch<{ message: string }>("/api/v1/auth/logout", { method: "POST" }),
};

export const businesses = {
  list: () => apiFetch<Business[]>("/api/v1/businesses"),
  get: (slug: string) => apiFetch<Business>(`/api/v1/businesses/${slug}`),
  search: (params: Record<string, string>) => {
    const qs = new URLSearchParams(params).toString();
    return apiFetch<Business[]>(`/api/v1/search/businesses?${qs}`);
  },
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

export const dashboard = {
  merchant: (businessId: string) => apiFetch<Record<string, unknown>>(`/api/v1/dashboard/merchant/${businessId}`),
  insights: (businessId: string) =>
    apiFetch<Record<string, unknown>>(`/api/v1/ai/businesses/${businessId}/insights`),
};

export { API_URL };
