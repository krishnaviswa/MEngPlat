import { BusinessCard } from "@/components/BusinessCard";
import { FilterPanel } from "@/components/FilterPanel";
import { SearchBar } from "@/components/SearchBar";
import { businesses } from "@/lib/api";

interface Props {
  searchParams: Promise<{ q?: string; city?: string; category?: string; min_rating?: string }>;
}

/** Search page — SSR with URL searchParams. */
export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const query: Record<string, string> = {};
  if (params.q) query.q = params.q;
  if (params.city) query.city = params.city;
  if (params.category) query.category = params.category;
  if (params.min_rating) query.min_rating = params.min_rating;

  let results: Awaited<ReturnType<typeof businesses.search>> = [];
  try {
    results = Object.keys(query).length ? await businesses.search(query) : await businesses.list();
  } catch {
    results = [];
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <SearchBar defaultValue={params.q} className="mb-6" />
      <div className="grid gap-6 lg:grid-cols-4">
        <FilterPanel />
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
