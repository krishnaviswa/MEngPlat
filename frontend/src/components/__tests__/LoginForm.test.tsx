import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { LoginForm } from "@/components/LoginForm";
import { auth, redirectAfterAuth } from "@/lib/api";

// Stable across renders -- see RequireAuth.test.tsx for why a fresh object
// literal per call would be a problem for hook-dependency identity.
const searchParamsMock = new URLSearchParams();

jest.mock("next/navigation", () => ({
  useSearchParams: () => searchParamsMock,
}));

jest.mock("../../lib/api", () => ({
  auth: {
    login: jest.fn(),
    totpSetup: jest.fn(),
    totpConfirm: jest.fn(),
    totpVerify: jest.fn(),
    google: jest.fn(),
    phoneRequest: jest.fn(),
    phoneVerify: jest.fn(),
    me: jest.fn(),
  },
  redirectAfterAuth: jest.fn(),
}));

const loginMock = auth.login as jest.Mock;
const totpSetupMock = auth.totpSetup as jest.Mock;
const totpConfirmMock = auth.totpConfirm as jest.Mock;
const totpVerifyMock = auth.totpVerify as jest.Mock;
const redirectAfterAuthMock = redirectAfterAuth as jest.Mock;

function fillCredentials(email = "user@example.com", password = "password123") {
  fireEvent.change(screen.getByPlaceholderText("Email"), { target: { value: email } });
  fireEvent.change(screen.getByPlaceholderText("Password"), { target: { value: password } });
}

describe("LoginForm", () => {
  const originalLocation = window.location;

  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(window, "location", {
      configurable: true,
      writable: true,
      value: { ...originalLocation, href: "" },
    });
  });

  afterAll(() => {
    Object.defineProperty(window, "location", {
      configurable: true,
      writable: true,
      value: originalLocation,
    });
  });

  // S-020 AC1: a password account without TOTP must be routed into
  // enrollment (QR + secret) before any session tokens exist.
  it("routes a first-time password login into the enroll step and fetches the QR/secret", async () => {
    loginMock.mockResolvedValue({ mfa_enrollment_required: true, mfa_token: "mfa-enroll-1" });
    totpSetupMock.mockResolvedValue({
      otpauth_uri: "otpauth://totp/x",
      secret: "SECRET123",
      qr_svg: "<svg>qr</svg>",
    });

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));

    expect(await screen.findByText("Set up authenticator")).toBeInTheDocument();
    await waitFor(() => expect(totpSetupMock).toHaveBeenCalledWith("mfa-enroll-1"));
    expect(await screen.findByText("SECRET123")).toBeInTheDocument();
    expect(redirectAfterAuthMock).not.toHaveBeenCalled();
  });

  // S-020 AC1: confirming enrollment with a correct first code is what
  // actually issues session tokens.
  it("issues session tokens and navigates away once enrollment is confirmed with a correct code", async () => {
    loginMock.mockResolvedValue({ mfa_enrollment_required: true, mfa_token: "mfa-enroll-1" });
    totpSetupMock.mockResolvedValue({
      otpauth_uri: "otpauth://totp/x",
      secret: "SECRET123",
      qr_svg: "<svg>qr</svg>",
    });
    totpConfirmMock.mockResolvedValue({ access_token: "a1", refresh_token: "r1" });

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));
    await screen.findByText("SECRET123");

    fireEvent.change(screen.getByPlaceholderText("6-digit code"), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /confirm and sign in/i }));

    await waitFor(() => expect(totpConfirmMock).toHaveBeenCalledWith("mfa-enroll-1", "123456"));
    await waitFor(() =>
      expect(redirectAfterAuthMock).toHaveBeenCalledWith({ access_token: "a1", refresh_token: "r1" }),
    );
  });

  // S-035: the credentials step must offer a way into the forgot-password flow.
  it("shows a Forgot password? link to /forgot-password on the credentials step", () => {
    render(<LoginForm />);
    expect(screen.getByText("Forgot password?").closest("a")).toHaveAttribute("href", "/forgot-password");
  });

  // S-020 AC2: a password account that already has TOTP enrolled is routed
  // straight to the verify step, not enrollment.
  it("routes a returning TOTP-enrolled login into the verify step, skipping setup", async () => {
    loginMock.mockResolvedValue({ mfa_required: true, mfa_token: "mfa-verify-1" });

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));

    expect(await screen.findByText("Authenticator code")).toBeInTheDocument();
    expect(totpSetupMock).not.toHaveBeenCalled();
  });

  // S-020 AC2: a correct verify code issues session tokens.
  it("issues session tokens and navigates away once a correct verify code is submitted", async () => {
    loginMock.mockResolvedValue({ mfa_required: true, mfa_token: "mfa-verify-1" });
    totpVerifyMock.mockResolvedValue({ access_token: "a2", refresh_token: "r2" });

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));
    await screen.findByText("Authenticator code");

    fireEvent.change(screen.getByPlaceholderText("6-digit code"), { target: { value: "654321" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() => expect(totpVerifyMock).toHaveBeenCalledWith("mfa-verify-1", "654321"));
    await waitFor(() =>
      expect(redirectAfterAuthMock).toHaveBeenCalledWith({ access_token: "a2", refresh_token: "r2" }),
    );
  });

  // S-020 AC4: a wrong code must surface an error and must not issue tokens
  // or navigate away.
  it("shows an error and stores no tokens when the verify code is wrong", async () => {
    loginMock.mockResolvedValue({ mfa_required: true, mfa_token: "mfa-verify-1" });
    totpVerifyMock.mockRejectedValue(new Error("Invalid authenticator code"));

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));
    await screen.findByText("Authenticator code");

    fireEvent.change(screen.getByPlaceholderText("6-digit code"), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    expect(await screen.findByText("Invalid authenticator code")).toBeInTheDocument();
    expect(redirectAfterAuthMock).not.toHaveBeenCalled();
  });

  // S-020 AC4: same guarantee on the enrollment-confirm path.
  it("shows an error and stores no tokens when the enrollment confirm code is wrong", async () => {
    loginMock.mockResolvedValue({ mfa_enrollment_required: true, mfa_token: "mfa-enroll-1" });
    totpSetupMock.mockResolvedValue({
      otpauth_uri: "otpauth://totp/x",
      secret: "SECRET123",
      qr_svg: "<svg>qr</svg>",
    });
    totpConfirmMock.mockRejectedValue(new Error("Invalid authenticator code"));

    render(<LoginForm />);
    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: /^sign in$/i }));
    await screen.findByText("SECRET123");

    fireEvent.change(screen.getByPlaceholderText("6-digit code"), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /confirm and sign in/i }));

    expect(await screen.findByText("Invalid authenticator code")).toBeInTheDocument();
    expect(redirectAfterAuthMock).not.toHaveBeenCalled();
  });

  // S-068 AC1/AC2: the login screen exposes a phone-OTP option that carries a
  // role selector through to PhoneOtpPanel, defaulting to "customer" and
  // mirroring RegisterForm's role choice (no "admin" option).
  it("renders a 'Signing in as' role selector defaulting to customer, with only customer/merchant options, and passes the picked role into the phone-OTP verify call", async () => {
    const { phoneVerify, phoneRequest } = jest.requireMock("../../lib/api").auth as {
      phoneVerify: jest.Mock;
      phoneRequest: jest.Mock;
    };
    phoneRequest.mockResolvedValue({ message: "sent" });
    phoneVerify.mockResolvedValue({ access_token: "a", refresh_token: "r" });

    render(<LoginForm />);

    const roleSelect = screen.getByLabelText(/signing in as/i) as HTMLSelectElement;
    expect(roleSelect.value).toBe("customer");
    const optionValues = Array.from(roleSelect.options).map((o) => o.value);
    expect(optionValues).toEqual(["customer", "merchant"]);

    fireEvent.change(roleSelect, { target: { value: "merchant" } });

    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(phoneRequest).toHaveBeenCalled());

    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() =>
      expect(phoneVerify).toHaveBeenCalledWith(expect.objectContaining({ role: "merchant" })),
    );
  });

  // S-068 AC5: static help copy above PhoneOtpPanel warns an existing
  // merchant that phone sign-in only matches an already-verified number.
  it("shows help copy above the phone panel warning phone sign-in only matches an already-verified number", () => {
    render(<LoginForm />);
    expect(
      screen.getByText(/only works if you.*ve verified this exact number before/i),
    ).toBeInTheDocument();
  });
});
