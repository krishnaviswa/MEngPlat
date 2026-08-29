import { fireEvent, render, screen, within } from "@testing-library/react";
import { NavbarMobileMenu } from "@/components/NavbarMobileMenu";

// S-122: NavbarMobileMenu itself does not read the router, but its children
// (NavLink) do in production. Mock next/navigation per-file to match repo idiom.
jest.mock("next/navigation", () => ({
  usePathname: jest.fn(() => "/"),
}));

const PANEL_ID = "navbar-mobile-menu";

function renderMenu() {
  return render(
    <div>
      <NavbarMobileMenu>
        <a href="/search">Search</a>
        <a href="/login">Login</a>
      </NavbarMobileMenu>
      <button type="button">outside</button>
    </div>,
  );
}

describe("NavbarMobileMenu (S-122)", () => {
  // AC10: the toggle is a real <button> with an accessible name and the ARIA
  // wiring — aria-expanded reflects state, aria-controls points at the panel id.
  it("renders a button toggle wired to the panel with aria-controls / aria-expanded", () => {
    renderMenu();

    const toggle = screen.getByRole("button", { name: "Menu" });
    expect(toggle.tagName).toBe("BUTTON");
    expect(toggle).toHaveAttribute("type", "button");
    expect(toggle).toHaveAttribute("aria-expanded", "false");
    expect(toggle).toHaveAttribute("aria-controls", PANEL_ID);

    expect(document.getElementById(PANEL_ID)).toBeInTheDocument();
  });

  // AC14: open defaults to false -> SSR / first client paint is collapsed. The
  // panel carries the `hidden` class and aria-expanded="false" — no expanded-
  // then-snap-shut hydration flash.
  it("defaults to collapsed on first render (hydration-safe)", () => {
    renderMenu();

    expect(screen.getByRole("button", { name: "Menu" })).toHaveAttribute("aria-expanded", "false");
    expect(document.getElementById(PANEL_ID)).toHaveClass("hidden");
  });

  // AC11: the secondary links are rendered exactly once — one reflowed subtree,
  // not a duplicated md:hidden copy — so single-match queries resolve.
  it("renders each child link exactly once while collapsed", () => {
    renderMenu();

    expect(screen.getAllByRole("link", { name: "Search" })).toHaveLength(1);
    expect(screen.getAllByRole("link", { name: "Login" })).toHaveLength(1);
  });

  // AC11: the children live inside #navbar-mobile-menu (scope panel assertions
  // with within(), not CSS visibility — jsdom cannot evaluate @media).
  it("keeps the child links inside #navbar-mobile-menu", () => {
    renderMenu();

    const panel = document.getElementById(PANEL_ID) as HTMLElement;
    expect(within(panel).getByRole("link", { name: "Search" })).toBeInTheDocument();
    expect(within(panel).getByRole("link", { name: "Login" })).toBeInTheDocument();
  });

  // AC10: activating the toggle opens the menu — aria-expanded flips true, the
  // accessible name switches to "Close menu", the panel drops the `hidden` class.
  it("opens on click: aria-expanded=true, name -> 'Close menu', panel shown", () => {
    renderMenu();

    fireEvent.click(screen.getByRole("button", { name: "Menu" }));

    const openToggle = screen.getByRole("button", { name: "Close menu" });
    expect(openToggle).toHaveAttribute("aria-expanded", "true");
    expect(document.getElementById(PANEL_ID)).not.toHaveClass("hidden");
    // still exactly one of each child after reflow
    expect(screen.getAllByRole("link", { name: "Search" })).toHaveLength(1);
  });

  // AC10: clicking the toggle again closes it.
  it("toggles closed on a second click", () => {
    renderMenu();

    fireEvent.click(screen.getByRole("button", { name: "Menu" }));
    fireEvent.click(screen.getByRole("button", { name: "Close menu" }));

    expect(screen.getByRole("button", { name: "Menu" })).toHaveAttribute("aria-expanded", "false");
    expect(document.getElementById(PANEL_ID)).toHaveClass("hidden");
  });

  // AC10: Escape while open closes the menu AND returns focus to the toggle.
  it("closes on Escape and returns focus to the toggle", () => {
    renderMenu();
    fireEvent.click(screen.getByRole("button", { name: "Menu" }));

    fireEvent.keyDown(document.body, { key: "Escape" });

    const toggle = screen.getByRole("button", { name: "Menu" });
    expect(toggle).toHaveAttribute("aria-expanded", "false");
    expect(toggle).toHaveFocus();
  });

  // AC10: a mousedown outside the menu root closes it.
  it("closes on an outside mousedown", () => {
    renderMenu();
    fireEvent.click(screen.getByRole("button", { name: "Menu" }));

    fireEvent.mouseDown(screen.getByRole("button", { name: "outside" }));

    expect(screen.getByRole("button", { name: "Menu" })).toHaveAttribute("aria-expanded", "false");
  });

  // AC10: a mousedown INSIDE the open menu (e.g. on a link) does not close it.
  it("keeps the menu open on an inside mousedown", () => {
    renderMenu();
    fireEvent.click(screen.getByRole("button", { name: "Menu" }));

    fireEvent.mouseDown(screen.getByRole("link", { name: "Search" }));

    expect(screen.getByRole("button", { name: "Close menu" })).toHaveAttribute("aria-expanded", "true");
  });

  // AC10: with the menu closed the document listeners are detached — Escape is a
  // harmless no-op, does not throw.
  it("ignores Escape while the menu is closed", () => {
    renderMenu();

    expect(() => fireEvent.keyDown(document.body, { key: "Escape" })).not.toThrow();
    expect(screen.getByRole("button", { name: "Menu" })).toHaveAttribute("aria-expanded", "false");
    expect(document.getElementById(PANEL_ID)).toHaveClass("hidden");
  });

  // AC11: child links stay single-instance across repeated open/close cycles.
  it("never duplicates child links across open/close cycles", () => {
    renderMenu();

    for (let i = 0; i < 3; i++) {
      fireEvent.click(screen.getByRole("button", { name: /menu/i }));
    }

    expect(screen.getAllByRole("link", { name: "Search" })).toHaveLength(1);
    expect(screen.getAllByRole("link", { name: "Login" })).toHaveLength(1);
  });
});
