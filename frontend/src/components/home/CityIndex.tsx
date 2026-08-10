interface CityIndexProps {
  cities: { name: string; count: number }[];
}

/** CityIndex — dense neighborhood links with listing counts derived from live data. */
export function CityIndex({ cities }: CityIndexProps) {
  if (cities.length === 0) return null;

  return (
    <section className="mh-section-reveal mx-auto max-w-6xl px-4 py-16">
      <div className="max-w-2xl">
        <h2 className="font-display text-3xl font-semibold tracking-tight text-slate-900">
          Neighborhoods on the map
        </h2>
        <p className="mt-2 text-slate-600">
          Jump into a city with approved listings — counts update from the live catalog.
        </p>
      </div>
      <ul className="mt-8 grid gap-x-8 gap-y-4 sm:grid-cols-2 lg:grid-cols-4">
        {cities.map((city) => (
          <li key={city.name} className="border-b border-slate-200 pb-3">
            <a
              href={`/search?city=${encodeURIComponent(city.name)}`}
              className="group flex items-baseline justify-between gap-3"
            >
              <span className="font-display text-lg font-medium text-slate-900 group-hover:text-brand-700">
                {city.name}
              </span>
              <span className="shrink-0 text-sm tabular-nums text-slate-500">
                {city.count} {city.count === 1 ? "listing" : "listings"}
              </span>
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
