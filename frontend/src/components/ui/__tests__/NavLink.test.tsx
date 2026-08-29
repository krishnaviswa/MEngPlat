import { render, screen } from "@testing-library/react";
import { usePathname } from "next/navigation";
import { NavLink } from "@/components/ui/NavLink";

// S-122: NavLink is the only client concern in the navbar shell — it reads the
// current path via usePathname(). Mock it per-file (matches the ~15 existing
// suites that mock next/navigation; no global mock in jest.setup.js).
jest.mock("next/navigation", () => ({
  usePathname: jest.fn(() => "/"),
}));

const pathnameMock = usePathname as jest.Mock;

beforeEach(() => {
  pathnameMock.mockReturnValue("/");
});

describe("NavLink (S-122)", () => {
  // AC4 / AC7: on a non-matching route the link is a plain anchor — href + label,
  // no aria-current, muted (non-active) styling.
  it("renders an anchor with href and children, inactive on a non-matching path", () => {
    pathnameMock.mockReturnValue("/");
    render(<NavLink href="/search">Search</NavLink>);

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).toHaveAttribute("href", "/search");
    expect(link).not.toHaveAttribute("aria-current");
    expect(link).toHaveClass("text-muted");
    expect(link).not.toHaveClass("font-semibold");
  });

  // AC4 / AC5: exact match -> aria-current="page" + the non-colour weight cue.
  it("marks aria-current=page and adds the weight cue when the path matches exactly", () => {
    pathnameMock.mockReturnValue("/search");
    render(<NavLink href="/search">Search</NavLink>);

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).toHaveAttribute("aria-current", "page");
    expect(link).toHaveClass("font-semibold");
    expect(link).toHaveClass("text-ink");
  });

  // AC6: usePathname() strips the query string, so /search?q=cafe&city=Pune
  // arrives as "/search" and still lights "Search" under match="exact".
  it("stays active when only a query string differed (usePathname drops it)", () => {
    pathnameMock.mockReturnValue("/search");
    render(<NavLink href="/search">Search</NavLink>);

    expect(screen.getByRole("link", { name: "Search" })).toHaveAttribute("aria-current", "page");
  });

  // AC7: "Search" (match="exact") must NOT stay active on a business detail page.
  it("does not light an exact link on an unrelated nested route", () => {
    pathnameMock.mockReturnValue("/businesses/blue-bottle-cafe");
    render(<NavLink href="/search">Search</NavLink>);

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).not.toHaveAttribute("aria-current");
    expect(link).toHaveClass("text-muted");
  });

  // AC6: match="prefix" lights the parent on a nested route.
  it("lights a prefix link on a nested route (/admin/users -> /admin)", () => {
    pathnameMock.mockReturnValue("/admin/users");
    render(
      <NavLink href="/admin" match="prefix">
        Admin
      </NavLink>,
    );

    expect(screen.getByRole("link", { name: "Admin" })).toHaveAttribute("aria-current", "page");
  });

  // AC6: match="prefix" also lights on the exact parent path itself.
  it("lights a prefix link on the exact parent path (/admin)", () => {
    pathnameMock.mockReturnValue("/admin");
    render(
      <NavLink href="/admin" match="prefix">
        Admin
      </NavLink>,
    );

    expect(screen.getByRole("link", { name: "Admin" })).toHaveAttribute("aria-current", "page");
  });

  // AC5 / AC7: the default match ("exact") does NOT treat a nested route as active.
  it("does not light an exact-match link on a nested route", () => {
    pathnameMock.mockReturnValue("/admin/users");
    render(<NavLink href="/admin">Admin</NavLink>);

    expect(screen.getByRole("link", { name: "Admin" })).not.toHaveAttribute("aria-current");
  });

  // AC7: prefix match must respect the "/" segment boundary — "/administrator"
  // is a string prefix of neither a match nor "/admin/".
  it("prefix match respects the '/' segment boundary", () => {
    pathnameMock.mockReturnValue("/administrator");
    render(
      <NavLink href="/admin" match="prefix">
        Admin
      </NavLink>,
    );

    expect(screen.getByRole("link", { name: "Admin" })).not.toHaveAttribute("aria-current");
  });

  // Architect Risk #1: usePathname() returns null with no router context in
  // Next 15.1 (it does not throw) -> NavLink must render inactive, not crash.
  it("renders inactive (no crash) when usePathname() returns null", () => {
    pathnameMock.mockReturnValue(null);
    render(<NavLink href="/search">Search</NavLink>);

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).toBeInTheDocument();
    expect(link).not.toHaveAttribute("aria-current");
    expect(link).toHaveClass("text-muted");
  });

  // AC8 (DOM-level portion): the active treatment carries BOTH a non-colour cue
  // (font weight) AND a themed underline token for light + dark. The rendered
  // contrast ratio itself is a PM-visual / Playwright check (jsdom has no CSS).
  it("active treatment includes a non-colour cue and a dark-mode underline token", () => {
    pathnameMock.mockReturnValue("/search");
    render(<NavLink href="/search">Search</NavLink>);

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).toHaveClass("font-semibold"); // non-colour cue
    expect(link).toHaveClass("after:bg-brand-600"); // light-theme underline bar
    expect(link).toHaveClass("dark:after:bg-brand-300"); // dark-theme underline bar
  });

  // NavLink forwards a caller-supplied className alongside its own classes.
  it("merges a caller-supplied className", () => {
    pathnameMock.mockReturnValue("/");
    render(
      <NavLink href="/search" className="ml-2">
        Search
      </NavLink>,
    );

    const link = screen.getByRole("link", { name: "Search" });
    expect(link).toHaveClass("ml-2");
    expect(link).toHaveClass("inline-flex");
  });

  // AC1 (DOM-level): the >=44px hit-area class is present whether active or not.
  it("keeps the >=44px hit-area class whether active or not", () => {
    pathnameMock.mockReturnValue("/");
    const { rerender } = render(<NavLink href="/search">Search</NavLink>);
    expect(screen.getByRole("link", { name: "Search" })).toHaveClass("min-h-[44px]");

    pathnameMock.mockReturnValue("/search");
    rerender(<NavLink href="/search">Search</NavLink>);
    expect(screen.getByRole("link", { name: "Search" })).toHaveClass("min-h-[44px]");
  });
});
