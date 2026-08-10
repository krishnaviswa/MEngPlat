import type { Category } from "@/lib/api";

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
}

/** FilterPanel — sidebar filters for search page. Uses native form GET to /search. */
export function FilterPanel({ params, categories = [] }: FilterPanelProps) {
  return (
    <aside className="rounded-xl border bg-white p-4">
      <h3 className="font-semibold text-gray-900">Filters</h3>
      <div className="mt-3 flex flex-wrap gap-2">
        <a
          href={buildSearchHref({ city: "Chennai", page: "1" }, params)}
          className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100"
        >
          Chennai
        </a>
        <a
          href={buildSearchHref({ q: "Chrompet", page: "1" }, params)}
          className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100"
        >
          Chrompet
        </a>
        <a
          href={buildSearchHref({ q: "Radha Nagar", page: "1" }, params)}
          className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100"
        >
          Radha Nagar
        </a>
      </div>
      <form action="/search" method="get" className="mt-4 space-y-4">
        {params?.q && <input type="hidden" name="q" value={params.q} />}
        {params?.lat && <input type="hidden" name="lat" value={params.lat} />}
        {params?.lng && <input type="hidden" name="lng" value={params.lng} />}
        {params?.radius_km && <input type="hidden" name="radius_km" value={params.radius_km} />}
        <input type="hidden" name="page" value="1" />
        <div>
          <label className="text-sm text-gray-600">City</label>
          <input
            name="city"
            defaultValue={params?.city}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            placeholder="Chennai"
          />
        </div>
        <div>
          <label className="text-sm text-gray-600">Category</label>
          <select
            name="category"
            defaultValue={params?.category ?? ""}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="">All</option>
            {categories.map((c) => (
              <option key={c.id} value={c.slug}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-sm text-gray-600">Sort by</label>
          <select name="sort" defaultValue={params?.sort ?? "rating"} className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="rating">Highest rated</option>
            <option value="reviews">Most reviews</option>
            <option value="name">Name A–Z</option>
          </select>
        </div>
        <div>
          <label className="text-sm text-gray-600">Min rating</label>
          <select
            name="min_rating"
            defaultValue={params?.min_rating ?? ""}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="">Any</option>
            <option value="3">3+ stars</option>
            <option value="4">4+ stars</option>
            <option value="4.5">4.5+ stars</option>
          </select>
        </div>
        <button type="submit" className="w-full rounded bg-brand-600 py-2 text-sm text-white hover:bg-brand-700">
          Apply filters
        </button>
      </form>
    </aside>
  );
}
