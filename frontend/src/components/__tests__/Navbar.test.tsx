import { fireEvent, render, screen } from "@testing-library/react";
import { usePathname } from "next/navigation";
import { Navbar } from "@/components/Navbar";
import type { User } from "@/lib/api";

jest.mock("next/navigation", () => ({
  usePathname: jest.fn(() => "/"),
}));
// S-122: mark the bell with a testid (instead of `() => null`) so AC13's
// "bell iff signed in" is assertable. No poll timers are pulled in.
jest.mock("../NotificationBell", () => ({
  NotificationBell: () => <div data-testid="notification-bell" />,
}));
jest.mock("../ThemeToggle", () => ({
  ThemeToggle: () => null,
}));

const pathnameMock = usePathname as jest.Mock;

beforeEach(() => {
  pathnameMock.mockReturnValue("/");
});

const baseUser: User = {
  id: "u1",
  email: "ann@example.com",
  full_name: "Ann Customer",
  role: "customer",
  is_active: true,
};

describe("Navbar", () => {
  // S-085 AC1: signed-in user with avatar_url set -> the nav's user area shows
  // an avatar image, not bare text only.
  it("renders the user's avatar image when avatar_url is set", () => {
    render(<Navbar user={{ ...baseUser, avatar_url: "http://x/ann.png" }} />);

    const img = screen.getByAltText("Ann Customer");
    expect(img).toHaveAttribute("src", "http://x/ann.png");
    expect(img.closest("a")).toHaveAttribute("href", "/profile");
  });

  // S-085 AC2: signed-in user with no avatar_url -> initials fallback, still
  // linking to /profile.
  it("renders an initials fallback when avatar_url is null", () => {
    render(<Navbar user={{ ...baseUser, avatar_url: null }} />);

    expect(document.querySelector("img")).not.toBeInTheDocument();
    const initials = screen.getByText("AC");
    expect(initials.closest("a")).toHaveAttribute("href", "/profile");
  });

  // S-085 AC9: signed-out visitor sees no avatar-upload affordance at all.
  it("renders no avatar for a signed-out visitor", () => {
    render(<Navbar user={null} />);

    expect(document.querySelector("img")).not.toBeInTheDocument();
    expect(screen.queryByText("AC")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: /login/i })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /change profile photo/i })).not.toBeInTheDocument();
    expect(document.querySelector('input[type="file"]')).not.toBeInTheDocument();
  });

  // S-085 AC10: nav avatar is not AI-analyzed content.
  it("does not attach an AI suggestion badge to the nav avatar", () => {
    render(<Navbar user={{ ...baseUser, avatar_url: "http://x/ann.png" }} />);

    expect(screen.getByAltText("Ann Customer")).toBeInTheDocument();
    expect(screen.queryByText(/suggestion/i)).not.toBeInTheDocument();
  });

  // S-087 AC4: support lives in the footer, not the header (S-085 owns Navbar).
  it("does not add a Support or /support link in the header", () => {
    const { container } = render(<Navbar user={baseUser} />);
    expect(container.querySelector('a[href="/support"]')).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: /support/i })).not.toBeInTheDocument();
  });
});

describe("Navbar — S-122 shell (touch targets, active state, mobile menu)", () => {
  const merchantUser: User = { ...baseUser, id: "me1", full_name: "Moe Merchant", role: "merchant" };
  const adminUser: User = { ...baseUser, id: "ad1", full_name: "Amy Admin", role: "admin" };

  // AC9 / AC12: exactly one mobile-menu toggle, wired to the single panel id.
  it("renders exactly one mobile-menu toggle wired to #navbar-mobile-menu", () => {
    render(<Navbar user={adminUser} onLogout={() => {}} />);

    const toggle = screen.getByRole("button", { name: /^menu$/i });
    expect(toggle).toHaveAttribute("aria-controls", "navbar-mobile-menu");
    expect(
      screen
        .getAllByRole("button")
        .filter((b) => b.getAttribute("aria-controls") === "navbar-mobile-menu"),
    ).toHaveLength(1);
    expect(document.querySelectorAll("#navbar-mobile-menu")).toHaveLength(1);
  });

  // AC13: NotificationBell renders when and only when signed in.
  it("shows the NotificationBell only when signed in", () => {
    const { rerender } = render(<Navbar user={baseUser} onLogout={() => {}} />);
    expect(screen.getByTestId("notification-bell")).toBeInTheDocument();

    rerender(<Navbar user={null} />);
    expect(screen.queryByTestId("notification-bell")).not.toBeInTheDocument();
  });

  // AC13: the Logout control still invokes onLogout.
  it("calls onLogout when the Logout button is clicked", () => {
    const onLogout = jest.fn();
    render(<Navbar user={baseUser} onLogout={onLogout} />);

    fireEvent.click(screen.getByRole("button", { name: "Logout" }));
    expect(onLogout).toHaveBeenCalledTimes(1);
  });

  // AC11 / AC13: a signed-out visitor sees exactly one Login and one Sign Up link.
  it("signed-out: exactly one Login and one Sign Up link", () => {
    render(<Navbar user={null} />);

    expect(screen.getAllByRole("link", { name: "Login" })).toHaveLength(1);
    expect(screen.getAllByRole("link", { name: "Sign Up" })).toHaveLength(1);
    expect(screen.getByRole("link", { name: "Login" })).toHaveAttribute("href", "/login");
    expect(screen.getByRole("link", { name: "Sign Up" })).toHaveAttribute("href", "/register");
  });

  // AC1 / AC3 (DOM-level): every interactive navbar item carries the >=44px
  // hit-area class. Rendered pixel size is a PM-visual / Playwright check.
  it("applies the min-h-[44px] hit-area class to every interactive item (signed in)", () => {
    render(<Navbar user={merchantUser} onLogout={() => {}} />);

    expect(screen.getByRole("link", { name: "MerchantHub AI" })).toHaveClass("min-h-[44px]");
    expect(screen.getByRole("link", { name: "Search" })).toHaveClass("min-h-[44px]");
    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveClass("min-h-[44px]");
    expect(screen.getByRole("button", { name: "Logout" })).toHaveClass("min-h-[44px]");
    expect(screen.getByRole("button", { name: /^menu$/i })).toHaveClass("min-h-[44px]");
    expect(screen.getByText("Moe Merchant").closest("a")).toHaveClass("min-h-[44px]");
  });

  it("applies the min-h-[44px] hit-area class to Login and Sign Up (signed out)", () => {
    render(<Navbar user={null} />);

    expect(screen.getByRole("link", { name: "Login" })).toHaveClass("min-h-[44px]");
    expect(screen.getByRole("link", { name: "Sign Up" })).toHaveClass("min-h-[44px]");
  });

  // AC6: on /search the "Search" NavLink is the active section.
  it("marks Search active on /search", () => {
    pathnameMock.mockReturnValue("/search");
    render(<Navbar user={null} />);

    expect(screen.getByRole("link", { name: "Search" })).toHaveAttribute("aria-current", "page");
  });

  // AC6 + AC5: a merchant on a nested dashboard route sees "Dashboard" active
  // (prefix match), and it is the ONLY item with aria-current.
  it("marks Dashboard active for a merchant on a nested dashboard route (only one aria-current)", () => {
    pathnameMock.mockReturnValue("/merchant/dashboard/reviews");
    render(<Navbar user={merchantUser} onLogout={() => {}} />);

    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "Search" })).not.toHaveAttribute("aria-current");
    expect(document.querySelectorAll('[aria-current="page"]')).toHaveLength(1);
  });

  // AC6: an admin on /admin/users sees "Admin" active (prefix match).
  it("marks Admin active for an admin on /admin/users", () => {
    pathnameMock.mockReturnValue("/admin/users");
    render(<Navbar user={adminUser} onLogout={() => {}} />);

    expect(screen.getByRole("link", { name: "Admin" })).toHaveAttribute("aria-current", "page");
    expect(document.querySelectorAll('[aria-current="page"]')).toHaveLength(1);
  });

  // AC7: on a business detail page no navbar item is active and the brand/logo
  // link is not given aria-current.
  it("marks no item active on a business detail page", () => {
    pathnameMock.mockReturnValue("/businesses/blue-bottle-cafe");
    render(<Navbar user={adminUser} onLogout={() => {}} />);

    expect(document.querySelectorAll("[aria-current]")).toHaveLength(0);
    expect(screen.getByRole("link", { name: "Search" })).not.toHaveAttribute("aria-current");
  });

  // AC7: on the home page nothing is active (brand link is not NavLink-treated).
  it("marks no item active on the home page", () => {
    pathnameMock.mockReturnValue("/");
    render(<Navbar user={null} />);

    expect(document.querySelectorAll("[aria-current]")).toHaveLength(0);
  });

  // AC7: on /profile nothing is active.
  it("marks no item active on /profile", () => {
    pathnameMock.mockReturnValue("/profile");
    render(<Navbar user={baseUser} onLogout={() => {}} />);

    expect(document.querySelectorAll("[aria-current]")).toHaveLength(0);
  });

  // AC13: role-gated link visibility unchanged — merchant sees Dashboard not
  // Admin; admin sees Admin not Dashboard; customer sees neither.
  it("keeps role-gated link visibility", () => {
    const { rerender } = render(<Navbar user={merchantUser} onLogout={() => {}} />);
    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveAttribute(
      "href",
      "/merchant/dashboard",
    );
    expect(screen.queryByRole("link", { name: "Admin" })).not.toBeInTheDocument();

    rerender(<Navbar user={adminUser} onLogout={() => {}} />);
    expect(screen.getByRole("link", { name: "Admin" })).toHaveAttribute("href", "/admin");
    expect(screen.queryByRole("link", { name: "Dashboard" })).not.toBeInTheDocument();

    rerender(<Navbar user={baseUser} onLogout={() => {}} />);
    expect(screen.queryByRole("link", { name: "Dashboard" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Admin" })).not.toBeInTheDocument();
  });

  // AC13: brand/logo still links to "/".
  it("keeps the brand link pointing at /", () => {
    render(<Navbar user={null} />);
    expect(screen.getByRole("link", { name: "MerchantHub AI" })).toHaveAttribute("href", "/");
  });
});
