import { act, render, screen } from "@testing-library/react";
import { ClientLayout } from "@/app/ClientLayout";
import { auth } from "@/lib/api";

jest.mock("next-themes", () => ({
  ThemeProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

jest.mock("next/navigation", () => ({
  usePathname: jest.fn(() => "/"),
}));

jest.mock("../../components/Footer", () => ({
  Footer: () => null,
}));
jest.mock("../../components/NotificationBell", () => ({
  NotificationBell: () => null,
}));
jest.mock("../../components/ThemeToggle", () => ({
  ThemeToggle: () => null,
}));
jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn() },
  clearTokens: jest.fn(),
  performLogout: jest.fn(),
}));

const meMock = auth.me as jest.Mock;

const baseUser = {
  id: "u1",
  email: "ann@example.com",
  full_name: "Ann Customer",
  role: "customer" as const,
  is_active: true,
  avatar_url: "http://x/old-avatar.png",
};

describe("ClientLayout avatar sync (S-085 AC5)", () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem("access_token", "tok-1");
    jest.clearAllMocks();
    meMock.mockResolvedValue(baseUser);
  });

  it("updates the Navbar avatar when mh:user-updated fires", async () => {
    render(
      <ClientLayout>
        <div>child</div>
      </ClientLayout>,
    );

    expect(await screen.findByAltText("Ann Customer")).toHaveAttribute("src", "http://x/old-avatar.png");

    await act(async () => {
      window.dispatchEvent(
        new CustomEvent("mh:user-updated", {
          detail: { ...baseUser, avatar_url: "http://x/new-avatar.png" },
        }),
      );
    });

    expect(screen.getByAltText("Ann Customer")).toHaveAttribute("src", "http://x/new-avatar.png");
  });
});
