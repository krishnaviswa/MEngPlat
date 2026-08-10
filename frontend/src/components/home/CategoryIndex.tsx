import type { Category } from "@/lib/api";

interface CategoryIndexProps {
  categories: { category: Category; count: number }[];
}

/** CategoryIndex — searchable category index with live listing counts (no emoji tiles). */
export function CategoryIndex({ categories }: CategoryIndexProps) {
  if (categories.length === 0) return null;

  return (
    <section className="mh-section-reveal bg-slate-900 px-4 py-16 text-white">
      <div className="mx-auto max-w-6xl">
        <div className="max-w-2xl">
          <h2 className="font-display text-3xl font-semibold tracking-tight">Browse by category</h2>
          <p className="mt-2 text-slate-300">
            Filter search by what you need — cafés, clinics, salons, repair shops, and more.
          </p>
        </div>
        <ul className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {categories.map(({ category, count }) => (
            <li key={category.id}>
              <a
                href={`/search?category=${encodeURIComponent(category.slug)}`}
                className="group flex items-center justify-between gap-4 border-b border-slate-700 py-3 transition hover:border-brand-400"
              >
                <span className="font-display text-lg font-medium group-hover:text-brand-300">
                  {category.name}
                </span>
                <span className="text-sm tabular-nums text-slate-400">
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
