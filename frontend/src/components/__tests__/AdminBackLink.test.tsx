import { render, screen } from "@testing-library/react";
import { AdminBackLink } from "@/components/AdminBackLink";

describe("AdminBackLink (S-086)", () => {
  it("defaults to the Admin panel at /admin", () => {
    render(<AdminBackLink />);
    const link = screen.getByRole("link", { name: /admin panel/i });
    expect(link).toHaveAttribute("href", "/admin");
    expect(link).toHaveTextContent("←");
  });

  it("can point at the businesses list for a drill-down", () => {
    render(<AdminBackLink href="/admin/businesses" label="All businesses" />);
    expect(screen.getByRole("link", { name: /all businesses/i })).toHaveAttribute("href", "/admin/businesses");
  });
});
