import { render, screen } from "@testing-library/react";
import { Dashboard } from "@/components/Dashboard";

const navItems = [
  { href: "/merchant/dashboard", label: "Overview" },
  { href: "/merchant/businesses/new", label: "Add business" },
  { href: "/settings", label: "Settings" },
];

describe("Dashboard", () => {
  // S-074 AC1: existing nav links (Overview/Add business/Settings) remain, in addition to
  // an optional new sidePanel column.
  it("renders the sidePanel alongside the existing nav links and children when provided", () => {
    render(
      <Dashboard title="New listing" navItems={navItems} sidePanel={<div data-testid="side-panel">Guidance</div>}>
        <div data-testid="form">Form</div>
      </Dashboard>,
    );
    expect(screen.getByText("Overview")).toBeInTheDocument();
    expect(screen.getByText("Add business")).toBeInTheDocument();
    expect(screen.getByText("Settings")).toBeInTheDocument();
    expect(screen.getByTestId("side-panel")).toBeInTheDocument();
    expect(screen.getByTestId("form")).toBeInTheDocument();
  });

  // S-074 AC7: sidePanel does not appear on other Dashboard call sites (Overview, Settings)
  // that omit the prop -- additive/backward-compatible by construction.
  it("does not render a sidePanel column when the prop is omitted", () => {
    render(
      <Dashboard title="Overview" navItems={navItems}>
        <div data-testid="content">Overview content</div>
      </Dashboard>,
    );
    expect(screen.queryByTestId("side-panel")).not.toBeInTheDocument();
    expect(screen.getByTestId("content")).toBeInTheDocument();
  });
});
