import { render, screen } from "@testing-library/react";
import { Navbar } from "@/components/Navbar";
import type { User } from "@/lib/api";

jest.mock("../NotificationBell", () => ({
  NotificationBell: () => null,
}));
jest.mock("../ThemeToggle", () => ({
  ThemeToggle: () => null,
}));

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
