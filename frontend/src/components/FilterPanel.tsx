import type { Category } from "@/lib/api";
import { Select } from "@/components/ui/Select";

export type SearchFilterParams = {
  q?: string;
  city?: string;
  category?: string;
  min_rating?: string;
  sort?: string;
  page?: string;
  page_size?: string;
  lat?: string;
  lng?: string;
  radius_km?: string;
};

function buildSearchHref(overrides: Record<string, string | undefined>, params?: SearchFilterParams) {
  const merged = { ...params, ...overrides };
  const qs = new URLSearchParams(
    Object.entries(merged).filter(([, v]) => v != null && v !== "") as [string, string][],
  ).toString();
  return `/search${qs ? `?${qs}` : ""}`;
}

interface FilterPanelProps {
  /** Current URL search params — lat/lng/radius_km and q are preserved on submit. */
  params?: SearchFilterParams;
  /** Live categories from GET /businesses/categories/all */
  categories?: Category[];
  /** Distinct cities from GET /businesses/cities (approved listings). */
  cities?: string[];
}

/** FilterPanel — sidebar filters for search page. Uses native form GET to /search. */
export function FilterPanel({ params, categories = [], cities = [] }: FilterPanelProps) {
  const activeCity = params?.city?.trim().toLowerCase() ?? "";

  return (
    <aside className="rounded-xl border bg-surface-raised p-4">
      <h3 className="font-semibold text-ink">Filters</h3>
      {cities.length > 0 && (
        <div className="mt-3 flex flex-wrap gap-2">
          {cities.map((city) => {
            const selected = activeCity === city.toLowerCase();
            return (
              <a
                key={city}
                href={buildSearchHref({ city, q: "", page: "1" }, params)}
                className={
                  selected
                    ? "rounded-full bg-brand-600 px-3 py-1 text-xs font-medium text-white"
                    : "rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100 dark:bg-brand-900/30 dark:text-brand-300 dark:hover:bg-brand-900/50"
                }
              >
                {city}
              </a>
            );
          })}
        </div>
      )}
      <form action="/search" method="get" className="mt-4 space-y-4">
        {params?.q && <input type="hidden" name="q" value={params.q} />}
        {params?.lat && <input type="hidden" name="lat" value={params.lat} />}
        {params?.lng && <input type="hidden" name="lng" value={params.lng} />}
        {params?.radius_km && <input type="hidden" name="radius_km" value={params.radius_km} />}
        <input type="hidden" name="page" value="1" />
        <div>
          <label className="text-sm text-muted">City</label>
          <input
            name="city"
            defaultValue={params?.city}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            placeholder="Any city"
          />
        </div>
        <div>
          <label className="text-sm text-muted">Category</label>
          <Select name="category" defaultValue={params?.category ?? ""} className="mt-1">
            <option value="">All</option>
            {categories.map((c) => (
              <option key={c.id} value={c.slug}>
                {c.name}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <label className="text-sm text-muted">Sort by</label>
          <Select name="sort" defaultValue={params?.sort ?? "rating"} className="mt-1">
            <option value="rating">Highest rated</option>
            <option value="reviews">Most reviews</option>
            <option value="name">Name A–Z</option>
          </Select>
        </div>
        <div>
          <label className="text-sm text-muted">Min rating</label>
          <Select name="min_rating" defaultValue={params?.min_rating ?? ""} className="mt-1">
            <option value="">Any</option>
            <option value="3">3+ stars</option>
            <option value="4">4+ stars</option>
            <option value="4.5">4.5+ stars</option>
          </Select>
        </div>
        <button type="submit" className="w-full rounded bg-brand-600 py-2 text-sm text-white hover:bg-brand-700">
          Apply filters
        </button>
      </form>
    </aside>
  );
}
