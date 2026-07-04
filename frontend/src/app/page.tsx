import { BusinessCard } from "@/components/BusinessCard";
import { SearchBar } from "@/components/SearchBar";
import { businesses } from "@/lib/api";

/** Home page — SSR: fetches businesses on the server. */
export default async function HomePage() {
  let featured: Awaited<ReturnType<typeof businesses.list>> = [];
  try {
    featured = await businesses.list();
  } catch {
    featured = [];
  }

  return (
    <div>
      <section className="bg-gradient-to-br from-brand-700 to-brand-900 px-4 py-16 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold">Support local businesses you trust</h1>
          <p className="mt-4 text-brand-100">
            Discover neighborhood gems, read verified reviews, and help independent merchants thrive with AI-powered insights.
          </p>
          <div className="mt-8">
            <SearchBar className="mx-auto max-w-xl [&_input]:text-gray-900" />
          </div>
        </div>
      </section>
      <section className="mx-auto max-w-6xl px-4 py-12">
        <h2 className="text-2xl font-bold">Featured businesses</h2>
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {featured.length > 0 ? (
            featured.map((b) => <BusinessCard key={b.id} business={b} />)
          ) : (
            <p className="col-span-full text-gray-500">
              Start the backend with Docker Compose to see businesses here.
            </p>
          )}
        </div>
      </section>
    </div>
  );
}
