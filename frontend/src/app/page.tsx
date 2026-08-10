import { BusinessCard } from "@/components/BusinessCard";
import { SearchBar } from "@/components/SearchBar";
import { Card } from "@/components/ui/Card";
import { StatCard } from "@/components/ui/StatCard";
import { businesses, type Category, type PublicPlatformStats } from "@/lib/api";

/** Home page — SSR: hero, stats, categories, featured grid, how-it-works. */
export default async function HomePage() {
  const [listResult, searchResult, categoriesResult, statsResult] = await Promise.allSettled([
    businesses.list(),
    businesses.search({ city: "Chennai" }),
    businesses.categoriesAll(),
    businesses.stats(),
  ]);

  const featured = listResult.status === "fulfilled" ? listResult.value : [];
  const chrompet = searchResult.status === "fulfilled" ? searchResult.value : [];
  const categories: Category[] = categoriesResult.status === "fulfilled" ? categoriesResult.value : [];
  const stats: PublicPlatformStats | null = statsResult.status === "fulfilled" ? statsResult.value : null;

  const grid = (chrompet.length > 0 ? chrompet : featured).slice(0, 12);

  return (
    <div>
      <section className="bg-gradient-to-br from-brand-700 to-brand-900 px-4 py-16 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold">Support local businesses you trust</h1>
          <p className="mt-4 text-brand-100">
            Discover neighborhood gems around Chrompet and Radha Nagar — shop names, photos, ratings, and reviews in one
            place.
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

      {stats && (
        <section className="mx-auto max-w-6xl px-4 py-10">
          <div className="grid gap-4 sm:grid-cols-3">
            <StatCard label="Approved businesses" value={stats.total_businesses} />
            <StatCard label="Active reviews" value={stats.total_reviews} />
            <StatCard label="Categories" value={stats.total_categories} />
          </div>
        </section>
      )}

      {categories.length > 0 && (
        <section className="mx-auto max-w-6xl px-4 pb-10">
          <h2 className="text-2xl font-bold">Browse by category</h2>
          <p className="mt-1 text-sm text-gray-600">Jump straight into a search filtered by what you need</p>
          <div className="mt-6 grid gap-3 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
            {categories.map((c) => (
              <a key={c.id} href={`/search?category=${encodeURIComponent(c.slug)}`}>
                <Card className="transition hover:border-brand-300 hover:shadow-md">
                  <p className="text-2xl" aria-hidden>
                    {c.icon || "🏷️"}
                  </p>
                  <p className="mt-2 font-semibold text-gray-900">{c.name}</p>
                </Card>
              </a>
            ))}
          </div>
        </section>
      )}

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
              <code className="rounded bg-white px-1">docker compose up --build</code> so the backend seeds ~20 Chrompet /
              Radha Nagar shops, then refresh this page.
            </p>
          )}
        </div>
      </section>

      <section className="border-t bg-gray-50 px-4 py-14">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-2xl font-bold">How it works</h2>
          <p className="mx-auto mt-2 max-w-xl text-center text-sm text-gray-600">
            Three simple steps to find and support local businesses
          </p>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <Card>
              <p className="text-sm font-semibold text-brand-700">1. Search</p>
              <p className="mt-2 text-sm text-gray-700">Find shops near you by name, city, or category.</p>
            </Card>
            <Card>
              <p className="text-sm font-semibold text-brand-700">2. Compare</p>
              <p className="mt-2 text-sm text-gray-700">Read ratings and reviews to pick a place you trust.</p>
            </Card>
            <Card>
              <p className="text-sm font-semibold text-brand-700">3. Support local</p>
              <p className="mt-2 text-sm text-gray-700">Visit, share feedback, and help neighborhood businesses grow.</p>
            </Card>
          </div>
        </div>
      </section>
    </div>
  );
}
