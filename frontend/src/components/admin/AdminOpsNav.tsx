/** Compact jump nav for the admin operational console (S-090). */
const OPS_LINKS: { href: string; label: string }[] = [
  { href: "#admin-users", label: "Users" },
  { href: "/admin/businesses", label: "Merchants" },
  { href: "#pending-businesses", label: "Approvals" },
  { href: "#admin-categories", label: "Categories" },
  { href: "/admin/reviews", label: "Reviews" },
  { href: "#reported-reviews", label: "Reported reviews" },
  { href: "/admin/support", label: "Support tickets" },
  { href: "/admin/business-reports", label: "Shop reports" },
  { href: "/admin/whatsapp", label: "WhatsApp" },
  { href: "#admin-payments", label: "Payments" },
];

export function AdminOpsNav() {
  return (
    <nav aria-label="Admin operations" className="mt-6">
      <ul className="flex flex-wrap gap-2">
        {OPS_LINKS.map((item) => (
          <li key={item.href}>
            <a
              href={item.href}
              className="inline-block rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-sm font-medium transition hover:border-brand-300 hover:shadow-sm"
            >
              {item.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
