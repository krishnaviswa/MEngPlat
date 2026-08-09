import { apiFetch, auth } from "@/lib/api";

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
