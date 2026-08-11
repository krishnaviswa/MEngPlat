import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import ProfilePage from "@/components/ProfilePage";
import { auth, favorites } from "@/lib/api";

const replaceMock = jest.fn();
// Stable across renders -- see RequireAuth.test.tsx.
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn(), updateMe: jest.fn() },
  clearTokens: jest.fn(),
  favorites: { list: jest.fn() },
}));

const meMock = auth.me as jest.Mock;
const updateMeMock = auth.updateMe as jest.Mock;
const favoritesListMock = favorites.list as jest.Mock;

const baseUser = {
  id: "u1",
  email: "ann@example.com",
  full_name: "Ann Customer",
  role: "customer" as const,
  is_active: true,
  auth_provider: "password",
  totp_enabled: false,
};

describe("ProfilePage", () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem("access_token", "tok-1");
    jest.clearAllMocks();
    favoritesListMock.mockResolvedValue([]);
  });

  // S-019 AC1: phone, address, and national-ID type/number are editable
  // fields on /profile.
  it("renders phone, address, and national-ID fields once the profile loads", async () => {
    meMock.mockResolvedValue({
      ...baseUser,
      phone: "+1 555 0100",
      address_line1: "1 Main St",
      city: "Metropolis",
      national_id_type: "pan",
      national_id_number: "ABCDE1234F",
    });

    render(<ProfilePage />);

    expect(await screen.findByDisplayValue("+1 555 0100")).toBeInTheDocument();
    expect(screen.getByDisplayValue("1 Main St")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Metropolis")).toBeInTheDocument();
    expect(screen.getByDisplayValue("ABCDE1234F")).toBeInTheDocument();
    expect(screen.getByRole("combobox")).toHaveValue("pan");
  });

  // S-019 AC2: saving persists the edited fields via PATCH /auth/me.
  it("persists edited phone/address fields via auth.updateMe on save", async () => {
    meMock.mockResolvedValue({ ...baseUser, phone: "", address_line1: "" });
    updateMeMock.mockResolvedValue({
      ...baseUser,
      phone: "+1 999 0000",
      address_line1: "42 New St",
    });

    render(<ProfilePage />);
    const phoneInput = await screen.findByPlaceholderText("+91…");
    fireEvent.change(phoneInput, { target: { value: "+1 999 0000" } });
    fireEvent.change(screen.getByPlaceholderText("Address line 1"), {
      target: { value: "42 New St" },
    });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));

    await waitFor(() =>
      expect(updateMeMock).toHaveBeenCalledWith(
        expect.objectContaining({ phone: "+1 999 0000", address_line1: "42 New St" }),
      ),
    );
    expect(await screen.findByText("Profile updated.")).toBeInTheDocument();
  });

  // S-019 AC3: sign-in security is shown as status text with a tip, not a
  // toggle, for a password account with TOTP enabled.
  it("shows TOTP-enabled status as a security tip, not a toggle", async () => {
    meMock.mockResolvedValue({ ...baseUser, totp_enabled: true, auth_provider: "password" });

    render(<ProfilePage />);

    expect(await screen.findByText(/authenticator app enabled/i)).toBeInTheDocument();
    expect(screen.getByText(/an authenticator app is more secure/i)).toBeInTheDocument();
    expect(screen.queryByRole("checkbox")).not.toBeInTheDocument();
    expect(screen.queryByRole("switch")).not.toBeInTheDocument();
  });

  // S-019 AC3: a password account that hasn't enrolled TOTP yet is told
  // enrollment is required on next sign-in (mandatory, not optional).
  it("tells a not-yet-enrolled password account that authenticator setup is required next sign-in", async () => {
    meMock.mockResolvedValue({ ...baseUser, totp_enabled: false, auth_provider: "password" });

    render(<ProfilePage />);

    expect(
      await screen.findByText(/authenticator setup is required the next time you sign in/i),
    ).toBeInTheDocument();
  });

  // S-019 AC3: a Google-only account (no TOTP) shows the Google status
  // instead of a password-MFA prompt.
  it("shows Google sign-in status for a Google account without TOTP", async () => {
    meMock.mockResolvedValue({ ...baseUser, totp_enabled: false, auth_provider: "google" });

    render(<ProfilePage />);

    expect(await screen.findByText(/sign in with gmail\/google/i)).toBeInTheDocument();
  });

  it("redirects to /login and does not render the form when there is no stored token", async () => {
    localStorage.clear();

    render(<ProfilePage />);

    await waitFor(() => expect(replaceMock).toHaveBeenCalledWith("/login"));
    expect(screen.queryByText("Profile")).not.toBeInTheDocument();
    expect(meMock).not.toHaveBeenCalled();
  });
});
