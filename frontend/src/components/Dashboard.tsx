interface DashboardProps {
  title: string;
  description?: string;
  navItems: { href: string; label: string }[];
  children: React.ReactNode;
}

/** Dashboard — layout shell for merchant/admin pages with sidebar nav. */
export function Dashboard({ title, description, navItems, children }: DashboardProps) {
  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        {description && <p className="text-gray-600">{description}</p>}
      </div>
      <div className="grid gap-6 lg:grid-cols-4">
        <nav className="space-y-1 rounded-xl border bg-white p-4 lg:col-span-1">
          {navItems.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="block rounded px-3 py-2 text-sm text-gray-700 hover:bg-brand-50 hover:text-brand-700"
            >
              {item.label}
            </a>
          ))}
        </nav>
        <div className="lg:col-span-3">{children}</div>
      </div>
    </div>
  );
}
