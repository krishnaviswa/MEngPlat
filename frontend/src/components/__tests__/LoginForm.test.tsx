import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { LoginForm } from "@/components/LoginForm";
import { auth, storeTokens } from "@/lib/api";

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
  },
  storeTokens: jest.fn(),
}));

const loginMock = auth.login as jest.Mock;
const totpSetupMock = auth.totpSetup as jest.Mock;
const totpConfirmMock = auth.totpConfirm as jest.Mock;
const totpVerifyMock = auth.totpVerify as jest.Mock;
const storeTokensMock = storeTokens as jest.Mock;

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
    expect(storeTokensMock).not.toHaveBeenCalled();
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
      expect(storeTokensMock).toHaveBeenCalledWith({ access_token: "a1", refresh_token: "r1" }),
    );
    expect(window.location.href).toBe("/");
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
      expect(storeTokensMock).toHaveBeenCalledWith({ access_token: "a2", refresh_token: "r2" }),
    );
    expect(window.location.href).toBe("/");
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
    expect(storeTokensMock).not.toHaveBeenCalled();
    expect(window.location.href).toBe("");
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
    expect(storeTokensMock).not.toHaveBeenCalled();
    expect(window.location.href).toBe("");
  });
});
