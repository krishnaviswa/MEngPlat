/** Shared back link for admin drill-down screens (S-086). */
export function AdminBackLink({
  href = "/admin",
  label = "Admin panel",
}: {
  href?: string;
  label?: string;
}) {
  return (
    <a href={href} className="mb-4 inline-block text-sm text-brand-600 hover:underline">
      ← {label}
    </a>
  );
}
