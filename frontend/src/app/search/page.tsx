import { BusinessCard } from "@/components/BusinessCard";
import { BusinessMap } from "@/components/BusinessMapClient";
import { FilterPanel } from "@/components/FilterPanel";
import { SearchBar } from "@/components/SearchBar";
import { UseLocationButton } from "@/components/UseLocationButton";
import { businesses } from "@/lib/api";
import { businessMarkers } from "@/lib/mapMarkers";

interface Props {
  searchParams: Promise<{
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
  }>;
}

function buildPageHref(
  params: Record<string, string | undefined>,
  page: number,
): string {
  const next = { ...params, page: String(page) };
  const qs = new URLSearchParams(
    Object.entries(next).filter(([, v]) => v != null && v !== "") as [string, string][],
  ).toString();
  return `/search?${qs}`;
}

/** Search page — SSR with URL searchParams, pagination, sort, and optional OSM map. */
export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = Math.max(1, Number(params.page) || 1);
  const pageSize = Math.min(50, Math.max(1, Number(params.page_size) || 20));

  const query: Record<string, string> = {
    page: String(page),
    page_size: String(pageSize),
  };
  if (params.q) query.q = params.q;
  if (params.city) query.city = params.city;
  if (params.category) query.category = params.category;
  if (params.min_rating) query.min_rating = params.min_rating;
  if (params.sort) query.sort = params.sort;
  if (params.lat) query.lat = params.lat;
  if (params.lng) query.lng = params.lng;
  if (params.radius_km) query.radius_km = params.radius_km;

  let results: Awaited<ReturnType<typeof businesses.search>> = [];
  let categories: Awaited<ReturnType<typeof businesses.categoriesAll>> = [];
  let cities: string[] = [];
  try {
    const [searchResults, cats, cityList] = await Promise.all([
      businesses.search(query),
      businesses.categoriesAll(),
      businesses.cities(),
    ]);
    results = searchResults;
    categories = cats;
    cities = cityList;
  } catch {
    results = [];
    categories = [];
    cities = [];
  }

  const mapMarkers = businessMarkers(results);
  const hasUserLocation = params.lat && params.lng;
  const mapCenter: [number, number] | undefined = hasUserLocation
    ? [Number(params.lat), Number(params.lng)]
    : undefined;

  const hasPrev = page > 1;
  const hasNext = results.length >= pageSize;
  const hrefParams = {
    q: params.q,
    city: params.city,
    category: params.category,
    min_rating: params.min_rating,
    sort: params.sort,
    page_size: params.page_size,
    lat: params.lat,
    lng: params.lng,
    radius_km: params.radius_km,
  };

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <SearchBar defaultValue={params.q} className="mb-6" />
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <UseLocationButton />
        {hasUserLocation && (
          <p className="text-sm text-gray-500">
            Showing results near {Number(params.lat).toFixed(4)}, {Number(params.lng).toFixed(4)}
            {params.radius_km ? ` (${params.radius_km} km)` : ""}
          </p>
        )}
      </div>
      {mapMarkers.length > 0 && (
        <div className="mb-6">
          <BusinessMap markers={mapMarkers} center={mapCenter} zoom={hasUserLocation ? 12 : 11} height="360px" />
        </div>
      )}
      <div className="grid gap-6 lg:grid-cols-4">
        <FilterPanel params={params} categories={categories} cities={cities} />
        <div className="lg:col-span-3">
          <p className="mb-4 text-sm text-gray-500">
            {results.length} businesses on page {page}
          </p>
          <div className="grid gap-4 sm:grid-cols-2">
            {results.map((b) => (
              <BusinessCard key={b.id} business={b} />
            ))}
          </div>
          {(hasPrev || hasNext) && (
            <div className="mt-6 flex items-center justify-between">
              {hasPrev ? (
                <a href={buildPageHref(hrefParams, page - 1)} className="text-sm font-medium text-brand-700 hover:underline">
                  ← Previous
                </a>
              ) : (
                <span />
              )}
              {hasNext ? (
                <a href={buildPageHref(hrefParams, page + 1)} className="text-sm font-medium text-brand-700 hover:underline">
                  Next →
                </a>
              ) : (
                <span />
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
