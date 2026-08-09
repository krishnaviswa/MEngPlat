import { BusinessCard } from "@/components/BusinessCard";
import { SearchBar } from "@/components/SearchBar";
import { businesses } from "@/lib/api";

/** Home page — SSR: featured grid + Chrompet / Radha Nagar local directory. */
export default async function HomePage() {
  let featured: Awaited<ReturnType<typeof businesses.list>> = [];
  let chrompet: Awaited<ReturnType<typeof businesses.search>> = [];
  try {
    const [all, chennai] = await Promise.all([
      businesses.list(),
      businesses.search({ city: "Chennai" }),
    ]);
    featured = all;
    chrompet = chennai;
  } catch {
    featured = [];
    chrompet = [];
  }

  // Prefer Chennai shops with photos/reviews on the main grid when present.
  const grid = (chrompet.length > 0 ? chrompet : featured).slice(0, 12);

  return (
    <div>
      <section className="bg-gradient-to-br from-brand-700 to-brand-900 px-4 py-16 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold">Support local businesses you trust</h1>
          <p className="mt-4 text-brand-100">
            Discover neighborhood gems around Chrompet and Radha Nagar — shop names, photos, ratings, and reviews in one place.
          </p>
          <div className="mt-8">
            <SearchBar className="mx-auto max-w-xl [&_input]:text-gray-900" />
          </div>
          <p className="mt-4 text-sm text-brand-100">
            Try searching{" "}
            <a href="/search?city=Chennai" className="underline hover:text-white">
              Chennai
            </a>{" "}
            or{" "}
            <a href="/search?q=Chrompet" className="underline hover:text-white">
              Chrompet
            </a>
          </p>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-12">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-2xl font-bold">Chrompet &amp; Radha Nagar</h2>
            <p className="mt-1 text-sm text-gray-600">
              Local cafés, restaurants, salons, pharmacies, and shops with photos and reviews
            </p>
          </div>
          <a href="/search?city=Chennai" className="text-sm font-medium text-brand-700 hover:underline">
            View all in Chennai →
          </a>
        </div>
        <div className="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {grid.length > 0 ? (
            grid.map((b) => <BusinessCard key={b.id} business={b} />)
          ) : (
            <p className="col-span-full rounded-lg border border-dashed border-gray-300 bg-gray-50 p-6 text-gray-600">
              No businesses loaded yet. Start the stack with{" "}
              <code className="rounded bg-white px-1">docker compose up --build</code> so the backend
              seeds ~20 Chrompet / Radha Nagar shops, then refresh this page.
            </p>
          )}
        </div>
      </section>
    </div>
  );
}
