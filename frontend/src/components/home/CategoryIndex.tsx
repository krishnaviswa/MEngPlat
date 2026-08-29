import type { Category } from "@/lib/api";

interface CategoryIndexProps {
  categories: { category: Category; count: number }[];
}

/** CategoryIndex — searchable category index with live listing counts (no emoji tiles). */
export function CategoryIndex({ categories }: CategoryIndexProps) {
  if (categories.length === 0) return null;

  return (
    <section className="mh-section-reveal border-y border-border bg-surface-raised px-4 py-16 text-ink">
      <div className="mx-auto max-w-6xl">
        <div className="max-w-2xl">
          <h2 className="font-display text-3xl font-semibold tracking-tight">Browse by category</h2>
          <p className="mt-2 text-muted">
            Filter search by what you need — cafés, clinics, salons, repair shops, and more.
          </p>
        </div>
        <ul className="mt-10 grid gap-1 sm:grid-cols-2 lg:grid-cols-3">
          {categories.map(({ category, count }) => (
            <li key={category.id}>
              <a
                href={`/search?category=${encodeURIComponent(category.slug)}`}
                className="group flex min-h-[44px] items-center justify-between gap-4 border-b border-border py-2 transition hover:border-brand-500"
              >
                <span className="font-display text-lg font-medium group-hover:text-brand-700 dark:group-hover:text-brand-300">
                  {category.name}
                </span>
                <span className="text-sm tabular-nums text-muted">
                  {count > 0 ? `${count}` : "—"}
                </span>
              </a>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
