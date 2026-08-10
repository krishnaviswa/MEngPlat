import { BusinessCard } from "@/components/BusinessCard";
import { SearchBar } from "@/components/SearchBar";
import { Card } from "@/components/ui/Card";
import { StatCard } from "@/components/ui/StatCard";
import { businesses, type Category, type PublicPlatformStats } from "@/lib/api";

const HERO_CITY_LINK_CAP = 6;

/** Home page — SSR: hero, stats, categories, featured grid, how-it-works. */
export default async function HomePage() {
  const [listResult, citiesResult, categoriesResult, statsResult] = await Promise.allSettled([
    businesses.list(),
    businesses.cities(),
    businesses.categoriesAll(),
    businesses.stats(),
  ]);

  const listed = listResult.status === "fulfilled" ? listResult.value : [];
  const cities = citiesResult.status === "fulfilled" ? citiesResult.value : [];
  const categories: Category[] = categoriesResult.status === "fulfilled" ? categoriesResult.value : [];
  const stats: PublicPlatformStats | null = statsResult.status === "fulfilled" ? statsResult.value : null;

  const featuredCity = cities[0] ?? null;
  let cityFeatured = listed;
  if (featuredCity) {
    const searchResult = await Promise.allSettled([businesses.search({ city: featuredCity })]);
    const byCity = searchResult[0].status === "fulfilled" ? searchResult[0].value : [];
    if (byCity.length > 0) {
      cityFeatured = byCity;
    }
  }

  const grid = cityFeatured.slice(0, 12);
  const heroCities = cities.slice(0, HERO_CITY_LINK_CAP);

  return (
    <div>
      <section className="bg-gradient-to-br from-brand-700 to-brand-900 px-4 py-16 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold">Support local businesses you trust</h1>
          <p className="mt-4 text-brand-100">
            Discover neighborhood shops with photos, ratings, and reviews in one place.
          </p>
          <div className="mt-8">
            <SearchBar className="mx-auto max-w-xl [&_input]:text-gray-900" />
          </div>
          {heroCities.length > 0 && (
            <p className="mt-4 text-sm text-brand-100">
              Try searching{" "}
              {heroCities.map((city, i) => (
                <span key={city}>
                  {i > 0 && (i === heroCities.length - 1 ? " or " : ", ")}
                  <a href={`/search?city=${encodeURIComponent(city)}`} className="underline hover:text-white">
                    {city}
                  </a>
                </span>
              ))}
            </p>
          )}
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
            <h2 className="text-2xl font-bold">
              {featuredCity ? `Explore ${featuredCity}` : "Featured businesses"}
            </h2>
            <p className="mt-1 text-sm text-gray-600">
              Local cafés, restaurants, salons, pharmacies, and shops with photos and reviews
            </p>
          </div>
          {featuredCity ? (
            <a
              href={`/search?city=${encodeURIComponent(featuredCity)}`}
              className="text-sm font-medium text-brand-700 hover:underline"
            >
              View all in {featuredCity} →
            </a>
          ) : (
            <a href="/search" className="text-sm font-medium text-brand-700 hover:underline">
              View all →
            </a>
          )}
        </div>
        <div className="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {grid.length > 0 ? (
            grid.map((b) => <BusinessCard key={b.id} business={b} />)
          ) : (
            <p className="col-span-full rounded-lg border border-dashed border-gray-300 bg-gray-50 p-6 text-gray-600">
              No businesses yet — check that the API is reachable and seed ran, then refresh this page.
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
