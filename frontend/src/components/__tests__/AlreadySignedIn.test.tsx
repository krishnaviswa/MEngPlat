import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { auth, clearTokens, performLogout, roleLandingPath } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn() },
  clearTokens: jest.fn(),
  performLogout: jest.fn(),
  roleLandingPath: (role: string) => (role === "merchant" ? "/merchant/dashboard" : "/"),
}));

const meMock = auth.me as jest.Mock;
const clearTokensMock = clearTokens as jest.Mock;
const performLogoutMock = performLogout as jest.Mock;

describe("AlreadySignedIn", () => {
  beforeEach(() => {
    localStorage.clear();
    meMock.mockReset();
    clearTokensMock.mockReset();
    performLogoutMock.mockReset();
  });

  // S-069/S-067 AC7: no active session -> the wrapped form (children) renders unchanged,
  // no over-triggering of the guard.
  it("renders children (the real form) when there is no stored access token", async () => {
    render(
      <AlreadySignedIn>
        <div>real-login-form</div>
      </AlreadySignedIn>,
    );
    await waitFor(() => expect(screen.getByText("real-login-form")).toBeInTheDocument());
    expect(meMock).not.toHaveBeenCalled();
  });

  // S-069 AC5/spec: a merchant's "Continue" link is role-aware, landing on
  // /merchant/dashboard rather than the public home page (the fix this slice's spec
  // describes -- reusing roleLandingPath, not a hardcoded href="/").
  it("shows a role-aware Continue link to /merchant/dashboard for a signed-in merchant", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch Owner", email: "m@example.com" });

    render(
      <AlreadySignedIn>
        <div>real-login-form</div>
      </AlreadySignedIn>,
    );

    expect(await screen.findByText((_, el) => el?.textContent === "You're signed in as Merch Owner (merchant)." )).toBeInTheDocument();
    const continueLink = screen.getByRole("link", { name: /continue/i });
    expect(continueLink).toHaveAttribute("href", "/merchant/dashboard");
    expect(screen.queryByText("real-login-form")).not.toBeInTheDocument();
  });

  // S-069/S-067 AC1/AC2/AC6: block screen behavior is identical for every role -- a
  // customer (and, by the same unbranched code path, admin) lands on "/" via
  // roleLandingPath, not merchant-only special-casing.
  it("shows a role-aware Continue link to / for a signed-in customer", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "u2", role: "customer", full_name: "Cust", email: "c@example.com" });

    render(
      <AlreadySignedIn>
        <div>real-login-form</div>
      </AlreadySignedIn>,
    );

    expect(await screen.findByText((_, el) => el?.textContent === "You're signed in as Cust (customer)." )).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /continue/i })).toHaveAttribute("href", "/");
  });

  // S-069/S-067 AC1/AC2: explicit "log out and continue" affordance clears the session
  // before the next form can show.
  it("logs out and redirects to /login when 'Log out to sign in as someone else' is clicked", async () => {
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch Owner", email: "m@example.com" });

    render(
      <AlreadySignedIn>
        <div>real-login-form</div>
      </AlreadySignedIn>,
    );
    await screen.findByRole("button", { name: /log out to sign in as someone else/i });
    fireEvent.click(screen.getByRole("button", { name: /log out to sign in as someone else/i }));

    await waitFor(() => expect(performLogoutMock).toHaveBeenCalledWith("/login"));
  });

  // S-069/S-067 AC3 (adjacent regression): an invalid/expired token falls through to
  // children rather than showing a stale block screen.
  it("clears tokens and renders children when auth.me() fails for a stored token", async () => {
    localStorage.setItem("access_token", "stale-token");
    meMock.mockRejectedValue(new Error("401"));

    render(
      <AlreadySignedIn>
        <div>real-login-form</div>
      </AlreadySignedIn>,
    );

    await waitFor(() => expect(clearTokensMock).toHaveBeenCalled());
    expect(await screen.findByText("real-login-form")).toBeInTheDocument();
  });
});
