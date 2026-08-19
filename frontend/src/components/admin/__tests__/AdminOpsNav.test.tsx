import { render, screen } from "@testing-library/react";
import { AdminOpsNav } from "@/components/admin/AdminOpsNav";

describe("AdminOpsNav (S-090)", () => {
  it("exposes operations links for existing admin surfaces", () => {
    render(<AdminOpsNav />);

    const nav = screen.getByRole("navigation", { name: "Admin operations" });
    expect(nav).toBeInTheDocument();

    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute("href", "#admin-users");
    expect(screen.getByRole("link", { name: "Merchants" })).toHaveAttribute("href", "/admin/businesses");
    expect(screen.getByRole("link", { name: "Approvals" })).toHaveAttribute("href", "#pending-businesses");
    expect(screen.getByRole("link", { name: "Categories" })).toHaveAttribute("href", "#admin-categories");
    expect(screen.getByRole("link", { name: "Reviews" })).toHaveAttribute("href", "/admin/reviews");
    expect(screen.getByRole("link", { name: "Reported reviews" })).toHaveAttribute("href", "#reported-reviews");
    expect(screen.getByRole("link", { name: "Support tickets" })).toHaveAttribute("href", "/admin/support");
    expect(screen.getByRole("link", { name: "Shop reports" })).toHaveAttribute(
      "href",
      "/admin/business-reports",
    );
    expect(screen.getByRole("link", { name: "WhatsApp" })).toHaveAttribute("href", "/admin/whatsapp");
    expect(screen.getByRole("link", { name: "Payments" })).toHaveAttribute("href", "#admin-payments");
  });
});
