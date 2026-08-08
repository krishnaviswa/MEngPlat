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
}

export interface Review {
  id: string;
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
  photo_urls?: string[];
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
}

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("access_token");
}

export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: HeadersInit = {
    ...(options.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
    ...(options.headers || {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };

  const res = await fetch(`${API_URL}${path}`, { ...options, headers });
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
};

export const dashboard = {
  merchant: (businessId: string) => apiFetch<Record<string, unknown>>(`/api/v1/dashboard/merchant/${businessId}`),
  insights: (businessId: string) =>
    apiFetch<Record<string, unknown>>(`/api/v1/ai/businesses/${businessId}/insights`),
};

export { API_URL };
