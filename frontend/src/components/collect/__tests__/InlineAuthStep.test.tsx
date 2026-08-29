import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { InlineAuthStep } from "@/components/collect/InlineAuthStep";
import { auth, redirectAfterAuth, storeTokens } from "@/lib/api";

/**
 * S-121 AC4/AC5/AC9, component-level: `InlineAuthStep` on its own (not through
 * the full `/collect/[businessId]` page) — mirrors the intent of mobile's
 * `inline_auth_step_test.dart`. Confirms phone OTP (not password) is the
 * pre-selected default, that email+password remains reachable via the same
 * `AuthMethodToggle` used on `/login`, that a failed attempt surfaces an
 * inline error without authenticating, and that success stores tokens
 * directly (never `redirectAfterAuth` — ADR-018).
 *
 * Note: `GoogleSignInButton` renders nothing in this test environment because
 * `NEXT_PUBLIC_GOOGLE_CLIENT_ID` isn't set — a pre-existing, suite-wide gap
 * (see `LoginForm.test.tsx`, which has the same limitation), not specific to
 * this component. Its presence/behavior isn't asserted here for that reason.
 */

jest.mock("../../../lib/api", () => ({
  auth: {
    login: jest.fn(),
    totpSetup: jest.fn(),
    totpConfirm: jest.fn(),
    totpVerify: jest.fn(),
    google: jest.fn(),
    phoneRequest: jest.fn(),
    phoneVerify: jest.fn(),
  },
  redirectAfterAuth: jest.fn(),
  storeTokens: jest.fn(),
}));

const loginMock = auth.login as jest.Mock;
const phoneRequestMock = auth.phoneRequest as jest.Mock;
const phoneVerifyMock = auth.phoneVerify as jest.Mock;
const storeTokensMock = storeTokens as jest.Mock;
const redirectAfterAuthMock = redirectAfterAuth as jest.Mock;

describe("InlineAuthStep (S-121)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC4/AC5: default method is phone OTP, not email+password; password
  // remains reachable via the same toggle used on /login.
  it("shows the phone-OTP panel by default (not email+password), and reaches password via the toggle", () => {
    render(<InlineAuthStep onAuthenticated={jest.fn()} />);

    expect(screen.getByText(/sign in to post your review/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/mobile number/i)).toBeInTheDocument();
    expect(screen.queryByPlaceholderText("Email")).not.toBeInTheDocument();
    expect(screen.queryByPlaceholderText("Password")).not.toBeInTheDocument();
    expect(screen.getByRole("radio", { name: /mobile otp/i })).toHaveAttribute("aria-checked", "true");
    expect(screen.getByRole("radio", { name: /authenticator/i })).toHaveAttribute("aria-checked", "false");

    fireEvent.click(screen.getByRole("radio", { name: /authenticator/i }));

    expect(screen.getByPlaceholderText("Email")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("Password")).toBeInTheDocument();
    expect(screen.queryByLabelText(/mobile number/i)).not.toBeInTheDocument();
  });

  // AC9: wrong password credentials show an inline error and do not
  // authenticate.
  it("shows an inline error and does not authenticate when password credentials are wrong", async () => {
    const onAuthenticated = jest.fn();
    loginMock.mockRejectedValue(new Error("Incorrect email or password"));

    render(<InlineAuthStep onAuthenticated={onAuthenticated} />);
    fireEvent.click(screen.getByRole("radio", { name: /authenticator/i }));
    fireEvent.change(screen.getByPlaceholderText("Email"), { target: { value: "wrong@example.com" } });
    fireEvent.change(screen.getByPlaceholderText("Password"), { target: { value: "wrong-password" } });
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));

    expect(await screen.findByText("Incorrect email or password")).toBeInTheDocument();
    expect(onAuthenticated).not.toHaveBeenCalled();
    expect(storeTokensMock).not.toHaveBeenCalled();
    // Composed review state lives in the parent page, not this component —
    // this component staying mounted with the credentials fields intact is
    // what lets the customer retry without recomposing (AC9).
    expect(screen.getByPlaceholderText("Email")).toBeInTheDocument();
  });

  // AC9: a wrong OTP code shows an inline error and does not authenticate.
  it("shows an inline error and does not authenticate when the OTP code is wrong", async () => {
    const onAuthenticated = jest.fn();
    phoneRequestMock.mockResolvedValue({ message: "sent" });
    phoneVerifyMock.mockRejectedValue(new Error("Invalid code"));

    render(<InlineAuthStep onAuthenticated={onAuthenticated} />);
    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(phoneRequestMock).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    expect(await screen.findByText("Invalid code")).toBeInTheDocument();
    expect(onAuthenticated).not.toHaveBeenCalled();
    expect(storeTokensMock).not.toHaveBeenCalled();
  });

  // ADR-018 / AC6: on success, tokens are stored directly and the caller is
  // notified via onAuthenticated — never via redirectAfterAuth, which would
  // navigate away from the collect page and defeat auto-submit.
  it("stores tokens directly and calls onAuthenticated on a successful OTP sign-in, never redirectAfterAuth", async () => {
    const onAuthenticated = jest.fn();
    phoneRequestMock.mockResolvedValue({ message: "sent" });
    phoneVerifyMock.mockResolvedValue({ access_token: "a1", refresh_token: "r1" });

    render(<InlineAuthStep onAuthenticated={onAuthenticated} />);
    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(phoneRequestMock).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() => expect(onAuthenticated).toHaveBeenCalledTimes(1));
    expect(storeTokensMock).toHaveBeenCalledWith({ access_token: "a1", refresh_token: "r1" });
    expect(redirectAfterAuthMock).not.toHaveBeenCalled();
  });
});
