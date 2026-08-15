import { apiFetch, auth, dashboard, performLogout } from "@/lib/api";

function mockFetchOnce(response: { ok: boolean; status: number; json: () => Promise<unknown> }) {
  return jest.fn().mockResolvedValueOnce(response);
}

describe("apiFetch", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("attaches the bearer token when one is stored", async () => {
    localStorage.setItem("access_token", "tok-1");
    const fetchMock = jest
      .fn()
      .mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    await apiFetch("/api/v1/whatever");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/whatever",
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: "Bearer tok-1" }),
      }),
    );
  });

  it("on a 401, refreshes once and retries the original request with the new token", async () => {
    localStorage.setItem("access_token", "expired");
    localStorage.setItem("refresh_token", "refresh-1");

    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => ({ detail: "expired" }) })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ access_token: "new-access", refresh_token: "new-refresh" }),
      })
      .mockResolvedValueOnce({ ok: true, status: 200, json: async () => ({ data: "yes" }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    const result = await apiFetch("/api/v1/protected");

    expect(result).toEqual({ data: "yes" });
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock.mock.calls[1][0]).toBe(
      "http://localhost:8000/api/v1/auth/refresh?refresh_token=refresh-1",
    );
    expect(localStorage.getItem("access_token")).toBe("new-access");
    const retriedOptions = fetchMock.mock.calls[2][1] as RequestInit;
    expect((retriedOptions.headers as Record<string, string>).Authorization).toBe("Bearer new-access");
  });

  it("does not attempt a refresh-retry for auth endpoints themselves", async () => {
    localStorage.setItem("refresh_token", "refresh-1");
    const fetchMock = jest
      .fn()
      .mockResolvedValue({ ok: false, status: 401, json: async () => ({ detail: "bad creds" }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    await expect(apiFetch("/api/v1/auth/login", { method: "POST" })).rejects.toThrow("bad creds");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("surfaces the original 401 (not a generic error) when the refresh itself fails", async () => {
    localStorage.setItem("access_token", "expired");
    localStorage.setItem("refresh_token", "bad-refresh");

    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => ({ detail: "expired" }) })
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => ({ detail: "invalid refresh" }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    await expect(apiFetch("/api/v1/protected")).rejects.toThrow("expired");
    expect(fetchMock).toHaveBeenCalledTimes(2);
    // A failed refresh must clear stale tokens rather than leave a dead
    // access token sitting in storage looking valid.
    expect(localStorage.getItem("access_token")).toBeNull();
  });

  it("does not attempt a refresh when there is no refresh token to use", async () => {
    const fetchMock = mockFetchOnce({ ok: false, status: 401, json: async () => ({ detail: "unauthorized" }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    await expect(apiFetch("/api/v1/protected")).rejects.toThrow("unauthorized");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});

describe("performLogout", () => {
  const originalLocation = window.location;

  beforeEach(() => {
    localStorage.clear();
    Object.defineProperty(window, "location", {
      configurable: true,
      writable: true,
      value: { ...originalLocation, replace: jest.fn() },
    });
  });

  afterAll(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      writable: true,
      value: originalLocation,
    });
  });

  // S-018 AC1: logging out must revoke the token server-side, clear local
  // storage, and hard-navigate so ClientLayout remounts signed-out.
  it("revokes the session server-side, clears local tokens, and hard-navigates to the given path", async () => {
    localStorage.setItem("access_token", "tok-1");
    localStorage.setItem("refresh_token", "ref-1");
    const fetchMock = jest
      .fn()
      .mockResolvedValue({ ok: true, status: 200, json: async () => ({ message: "Logged out successfully." }) });
    global.fetch = fetchMock as unknown as typeof fetch;

    await performLogout("/login");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/auth/logout",
      expect.objectContaining({ method: "POST", body: JSON.stringify({ refresh_token: "ref-1" }) }),
    );
    expect(localStorage.getItem("access_token")).toBeNull();
    expect(localStorage.getItem("refresh_token")).toBeNull();
    expect(window.location.replace).toHaveBeenCalledWith("/login");
  });

  // S-018 AC1: local logout must proceed (tokens cleared, hard navigation)
  // even when the best-effort server revoke call fails.
  it("still clears local tokens and navigates when the server revoke call fails", async () => {
    localStorage.setItem("access_token", "tok-1");
    localStorage.setItem("refresh_token", "ref-1");
    const fetchMock = jest.fn().mockRejectedValue(new Error("network down"));
    global.fetch = fetchMock as unknown as typeof fetch;

    await performLogout();

    expect(localStorage.getItem("access_token")).toBeNull();
    expect(localStorage.getItem("refresh_token")).toBeNull();
    expect(window.location.replace).toHaveBeenCalledWith("/login");
  });
});

describe("auth.google", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("posts the Google ID token credential to /api/v1/auth/google", async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ access_token: "a", refresh_token: "b" }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    await auth.google({ credential: "id-token-abc" });

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/auth/google",
      expect.objectContaining({ method: "POST", body: JSON.stringify({ credential: "id-token-abc" }) }),
    );
  });
});

// S-035: forgot/reset password client calls.
describe("auth.forgotPassword", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("posts the email to /api/v1/auth/forgot-password", async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ message: "If an account exists for that email, we sent password-reset instructions." }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const result = await auth.forgotPassword("someone@example.com");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/auth/forgot-password",
      expect.objectContaining({ method: "POST", body: JSON.stringify({ email: "someone@example.com" }) }),
    );
    expect(result.message).toContain("If an account exists");
  });
});

describe("auth.resetPassword", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("posts token and new_password (snake_case) to /api/v1/auth/reset-password", async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ message: "Password updated. Sign in with your new password." }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    await auth.resetPassword("raw-token-123", "brandnewpass123");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/auth/reset-password",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ token: "raw-token-123", new_password: "brandnewpass123" }),
      }),
    );
  });
});

describe("dashboard.benchmark", () => {
  it("GETs /api/v1/dashboard/merchant/{id}/benchmark", async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        business_id: "biz-1",
        own_rating: 4.5,
        category_median: null,
        city_median: 4.0,
        category_sample_size: 1,
        city_sample_size: 5,
        disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
      }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const result = await dashboard.benchmark("biz-1");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:8000/api/v1/dashboard/merchant/biz-1/benchmark",
      expect.anything(),
    );
    expect(result.disclaimer).toMatch(/not an AI judgment/i);
  });
});
