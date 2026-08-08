import figma from "@figma/code-connect";
import { Dashboard } from "./Dashboard";

// Figma: DashboardNav (Components / Navigation) is the sidebar rendered by this
// layout shell. `navItems` drives the NavItem instances inside it.
figma.connect(Dashboard, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=14-20", {
  example: () => (
    <Dashboard
      title="Merchant Dashboard"
      description={business.name}
      navItems={[
        { href: "/merchant/dashboard", label: "Overview" },
        { href: `/businesses/${business.slug}`, label: "Public profile" },
        { href: "/settings", label: "Settings" },
      ]}
    >
      {children}
    </Dashboard>
  ),
});
