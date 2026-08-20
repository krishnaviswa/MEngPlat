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
  auth: { me: jest.fn(), updateMe: jest.fn(), uploadAvatar: jest.fn() },
  clearTokens: jest.fn(),
  favorites: { list: jest.fn() },
}));

const meMock = auth.me as jest.Mock;
const updateMeMock = auth.updateMe as jest.Mock;
const uploadAvatarMock = auth.uploadAvatar as jest.Mock;
const favoritesListMock = favorites.list as jest.Mock;
let dispatchSpy: jest.SpyInstance;

function makeImageFile(name = "avatar.png", type = "image/png") {
  return new File(["fake-bytes"], name, { type });
}

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
    dispatchSpy = jest.spyOn(window, "dispatchEvent");
  });

  afterEach(() => {
    dispatchSpy.mockRestore();
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
        undefined,
      ),
    );
    expect(await screen.findByText("Profile updated.")).toBeInTheDocument();
    // S-085: avatar is upload-only now -- "Save changes" no longer batches it.
    expect(updateMeMock.mock.calls[0][0]).not.toHaveProperty("avatar_url");
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

  // S-085 AC3: the old manual "Avatar URL" text input is gone.
  it("no longer renders the Avatar URL text input", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: null });

    render(<ProfilePage />);

    await screen.findByText("Profile");
    expect(screen.queryByLabelText(/avatar url/i)).not.toBeInTheDocument();
  });

  // S-085 AC3/AC4: clicking the large avatar opens the hidden file input.
  it("opens the hidden file input when the avatar is clicked", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: null });

    render(<ProfilePage />);
    await screen.findByText("Profile");

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    expect(input).toHaveAttribute("accept", "image/jpeg,image/png,image/webp,image/gif");
    const clickSpy = jest.spyOn(input, "click");
    fireEvent.click(screen.getByRole("button", { name: /change profile photo/i }));

    expect(clickSpy).toHaveBeenCalled();
    expect(screen.getByText("Change photo")).toBeInTheDocument();
    clickSpy.mockRestore();
  });

  // S-085 AC5: a successful upload applies immediately via applyUser, independent
  // of "Save changes".
  it("uploads a selected avatar and shows it immediately on success", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: null });
    uploadAvatarMock.mockResolvedValue({ ...baseUser, avatar_url: "http://x/new-avatar.png" });

    render(<ProfilePage />);
    await screen.findByText("Profile");

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [makeImageFile()] } });

    await waitFor(() => expect(uploadAvatarMock).toHaveBeenCalled());
    expect(await screen.findByAltText("Ann Customer")).toHaveAttribute("src", "http://x/new-avatar.png");
    // Save changes was never involved.
    expect(updateMeMock).not.toHaveBeenCalled();
    const dispatched = dispatchSpy.mock.calls.some(
      ([event]) => event instanceof Event && event.type === "mh:user-updated",
    );
    expect(dispatched).toBe(true);
  });

  // S-085 AC6: a rejected upload (oversized/wrong-type) shows an inline error near
  // the avatar and leaves the previous avatar unchanged.
  it("shows an inline error and retains the previous avatar when the upload fails", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: null });
    uploadAvatarMock.mockRejectedValue(new Error("File too large. Max size is 5MB."));

    render(<ProfilePage />);
    await screen.findByText("Profile");

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [makeImageFile()] } });

    expect(await screen.findByText(/file too large/i)).toBeInTheDocument();
    // Still showing the initials fallback (no avatar_url was ever set) -- unchanged.
    expect(document.querySelector("img")).not.toBeInTheDocument();
    expect(screen.getByText("AC")).toBeInTheDocument();
  });

  it("retains a previous photo when a replacement upload is rejected", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: "http://x/old-avatar.png" });
    uploadAvatarMock.mockRejectedValue(new Error("Unsupported file type 'text/plain'."));

    render(<ProfilePage />);
    await screen.findByAltText("Ann Customer");

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [makeImageFile("notes.txt", "text/plain")] } });

    expect(await screen.findByText(/unsupported file type/i)).toBeInTheDocument();
    expect(screen.getByAltText("Ann Customer")).toHaveAttribute("src", "http://x/old-avatar.png");
  });

  // S-085 AC7: in-flight upload shows a visible pending state on the avatar.
  it("shows an uploading state on the avatar while the request is in flight", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: null });
    let resolveUpload: (value: typeof baseUser) => void = () => undefined;
    uploadAvatarMock.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveUpload = resolve;
        }),
    );

    render(<ProfilePage />);
    await screen.findByText("Profile");

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [makeImageFile()] } });

    expect(await screen.findByText(/uploading/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /change profile photo/i })).toBeDisabled();

    resolveUpload({ ...baseUser, avatar_url: "http://x/new-avatar.png" });
    expect(await screen.findByAltText("Ann Customer")).toHaveAttribute("src", "http://x/new-avatar.png");
    expect(screen.queryByText(/uploading/i)).not.toBeInTheDocument();
  });

  // S-085 AC10: avatar is plain profile data -- no AI suggestion copy/badge.
  it("does not show an AI suggestion badge or disclaimer on the avatar", async () => {
    meMock.mockResolvedValue({ ...baseUser, avatar_url: "http://x/ann.png" });

    render(<ProfilePage />);
    await screen.findByAltText("Ann Customer");

    expect(screen.queryByText(/suggestion/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/ai analysis/i)).not.toBeInTheDocument();
  });
});
