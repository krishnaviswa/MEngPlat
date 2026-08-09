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
    lat?: string;
    lng?: string;
    radius_km?: string;
  }>;
}

/** Search page — SSR with URL searchParams and optional OSM map. */
export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const query: Record<string, string> = {};
  if (params.q) query.q = params.q;
  if (params.city) query.city = params.city;
  if (params.category) query.category = params.category;
  if (params.min_rating) query.min_rating = params.min_rating;
  if (params.lat) query.lat = params.lat;
  if (params.lng) query.lng = params.lng;
  if (params.radius_km) query.radius_km = params.radius_km;

  let results: Awaited<ReturnType<typeof businesses.search>> = [];
  try {
    results = Object.keys(query).length ? await businesses.search(query) : await businesses.list();
  } catch {
    results = [];
  }

  const mapMarkers = businessMarkers(results);
  const hasUserLocation = params.lat && params.lng;
  const mapCenter: [number, number] | undefined = hasUserLocation
    ? [Number(params.lat), Number(params.lng)]
    : undefined;

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
        <FilterPanel params={params} />
        <div className="lg:col-span-3">
          <p className="mb-4 text-sm text-gray-500">{results.length} businesses found</p>
          <div className="grid gap-4 sm:grid-cols-2">
            {results.map((b) => (
              <BusinessCard key={b.id} business={b} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
