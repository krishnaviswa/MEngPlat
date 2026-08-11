import { act, render, screen, waitFor } from "@testing-library/react";
import { RequireAuth } from "@/components/RequireAuth";
import { auth, clearTokens } from "@/lib/api";

const replaceMock = jest.fn();
// A stable object reference matters here: RequireAuth's `verify` callback
// depends on `router`, so a mock that returns a fresh object every call
// would give `verify` a new identity every render and re-trigger the mount
// effect in a loop.
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn() },
  clearTokens: jest.fn(),
}));

const meMock = auth.me as jest.Mock;
const clearTokensMock = clearTokens as jest.Mock;

describe("RequireAuth", () => {
  beforeEach(() => {
    localStorage.clear();
    replaceMock.mockClear();
    meMock.mockReset();
    clearTokensMock.mockReset();
  });

  // S-018 AC2: Back to a protected page with no stored token sends the user
  // to login rather than rendering the authenticated shell.
  it("redirects to /login and renders nothing when there is no stored access token", async () => {
    render(<RequireAuth>protected-content</RequireAuth>);

    await waitFor(() => expect(replaceMock).toHaveBeenCalledWith("/login"));
    expect(screen.queryByText("protected-content")).not.toBeInTheDocument();
    expect(meMock).not.toHaveBeenCalled();
  });

  it("renders children once auth.me() resolves with a matching role", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "u1", role: "customer", full_name: "Ann" });

    render(<RequireAuth role="customer">protected-content</RequireAuth>);

    expect(await screen.findByText("protected-content")).toBeInTheDocument();
  });

  it("redirects home without rendering children when the role does not match", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "u1", role: "customer", full_name: "Ann" });

    render(<RequireAuth role="merchant">protected-content</RequireAuth>);

    await waitFor(() => expect(replaceMock).toHaveBeenCalledWith("/"));
    expect(screen.queryByText("protected-content")).not.toBeInTheDocument();
  });

  // S-018 AC3: a revoked/expired token makes auth.me() fail on a guarded
  // page -- local tokens must be cleared and the user sent to login.
  it("clears local tokens and redirects to /login when auth.me() fails", async () => {
    localStorage.setItem("access_token", "stale-token");
    meMock.mockRejectedValue(new Error("401"));

    render(<RequireAuth>protected-content</RequireAuth>);

    await waitFor(() => expect(clearTokensMock).toHaveBeenCalled());
    expect(replaceMock).toHaveBeenCalledWith("/login");
    expect(screen.queryByText("protected-content")).not.toBeInTheDocument();
  });

  // S-018 AC2/AC3: bfcache restore (Back button) re-runs the check; if the
  // token was revoked in the meantime, the restored page must not keep
  // showing the authenticated shell.
  it("re-verifies on a bfcache pageshow restore and clears tokens if the session is no longer valid", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValueOnce({ id: "u1", role: "customer", full_name: "Ann" });

    render(<RequireAuth>protected-content</RequireAuth>);
    expect(await screen.findByText("protected-content")).toBeInTheDocument();

    meMock.mockRejectedValueOnce(new Error("revoked"));
    await act(async () => {
      const event = new Event("pageshow") as Event & { persisted: boolean };
      event.persisted = true;
      window.dispatchEvent(event);
    });

    await waitFor(() => expect(clearTokensMock).toHaveBeenCalled());
    expect(replaceMock).toHaveBeenCalledWith("/login");
  });
});
