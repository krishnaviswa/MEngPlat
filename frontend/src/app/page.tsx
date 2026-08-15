import { SearchBar } from "@/components/SearchBar";
import { CategoryIndex } from "@/components/home/CategoryIndex";
import { CityIndex } from "@/components/home/CityIndex";
import { FeaturedGrid } from "@/components/home/FeaturedGrid";
import { ReviewVoices, type ReviewVoiceItem } from "@/components/home/ReviewVoices";
import { TrustMetrics } from "@/components/home/TrustMetrics";
import {
  API_URL,
  businesses,
  reviews,
  type Business,
  type Category,
  type PublicPlatformStats,
} from "@/lib/api";

const HERO_PHOTO_CAP = 6;
const FEATURED_CAP = 6;
const VOICE_BUSINESS_CAP = 3;

function settledErrorMessage(result: PromiseSettledResult<unknown>, label: string): string | null {
  if (result.status !== "rejected") return null;
  const reason = result.reason;
  const detail = reason instanceof Error ? reason.message : String(reason);
  return `${label}: ${detail}`;
}

function countByCity(list: Business[]): Map<string, number> {
  const map = new Map<string, number>();
  for (const b of list) {
    if (!b.city) continue;
    map.set(b.city, (map.get(b.city) || 0) + 1);
  }
  return map;
}

function countByCategorySlug(list: Business[]): Map<string, number> {
  const map = new Map<string, number>();
  for (const b of list) {
    for (const c of b.categories || []) {
      map.set(c.slug, (map.get(c.slug) || 0) + 1);
    }
  }
  return map;
}

/** Home page — SSR: brand hero, live metrics, indexes, featured, voices, journey, merchant CTA. */
export default async function HomePage() {
  const [listResult, citiesResult, categoriesResult, statsResult] = await Promise.allSettled([
    businesses.list(),
    businesses.cities(),
    businesses.categoriesAll(),
    businesses.stats(),
  ]);

  const loadErrors = [
    settledErrorMessage(listResult, "businesses.list"),
    settledErrorMessage(citiesResult, "businesses.cities"),
    settledErrorMessage(categoriesResult, "businesses.categoriesAll"),
    settledErrorMessage(statsResult, "businesses.stats"),
  ].filter((msg): msg is string => Boolean(msg));

  if (loadErrors.length > 0) {
    console.error(`[home] SSR API failures (API_URL=${API_URL}):`, loadErrors);
  }

  const listed = listResult.status === "fulfilled" ? listResult.value : [];
  const cities = citiesResult.status === "fulfilled" ? citiesResult.value : [];
  const categories: Category[] = categoriesResult.status === "fulfilled" ? categoriesResult.value : [];
  const statsRaw = statsResult.status === "fulfilled" ? statsResult.value : null;
  const stats: PublicPlatformStats | null =
    statsRaw &&
    typeof statsRaw.total_businesses === "number" &&
    typeof statsRaw.total_reviews === "number" &&
    typeof statsRaw.total_categories === "number" &&
    typeof statsRaw.total_cities === "number"
      ? statsRaw
      : null;

  const loadError =
    listed.length === 0 && cities.length === 0 && loadErrors.length > 0
      ? `API_URL=${API_URL} — ${loadErrors.join("; ")}`
      : null;

  const featuredCity = cities[0] ?? null;
  let cityFeatured = listed;
  if (featuredCity) {
    const searchResult = await Promise.allSettled([businesses.search({ city: featuredCity })]);
    const byCity = searchResult[0].status === "fulfilled" ? searchResult[0].value : [];
    if (byCity.length > 0) {
      cityFeatured = byCity;
    }
  }

  const grid = cityFeatured.slice(0, FEATURED_CAP);
  const cityCounts = countByCity(listed);
  const categoryCounts = countByCategorySlug(listed);

  const cityIndex = cities
    .map((name) => ({ name, count: cityCounts.get(name) || 0 }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));

  const categoryIndex = categories
    .map((category) => ({ category, count: categoryCounts.get(category.slug) || 0 }))
    .sort((a, b) => b.count - a.count || a.category.name.localeCompare(b.category.name));

  const heroPhotos = listed
    .map((b) => b.storefront_url || b.logo_url)
    .filter((url): url is string => Boolean(url))
    .slice(0, HERO_PHOTO_CAP);

  const voiceCandidates = grid.filter((b) => b.review_count > 0).slice(0, VOICE_BUSINESS_CAP);
  const voiceResults = await Promise.allSettled(voiceCandidates.map((b) => reviews.list(b.id)));
  const voiceItems: ReviewVoiceItem[] = [];
  voiceResults.forEach((result, i) => {
    if (result.status !== "fulfilled") return;
    const review = result.value.find((r) => r.body?.trim()) || result.value[0];
    if (!review) return;
    voiceItems.push({ business: voiceCandidates[i], review });
  });

  return (
    <div>
      {/* Hero — brand first; no overlays, stats, or category pills */}
      <section className="relative min-h-[min(88vh,720px)] overflow-hidden bg-slate-900 text-white">
        <div className="absolute inset-0" aria-hidden>
          {heroPhotos.length > 0 ? (
            <div className="grid h-full grid-cols-2 md:grid-cols-3">
              {heroPhotos.map((src, i) => (
                <div key={`${src}-${i}`} className="relative overflow-hidden">
                  <img
                    src={src}
                    alt=""
                    className="h-full w-full object-cover opacity-55 animate-ken-burns"
                    style={{ animationDelay: `${i * 1.2}s` }}
                  />
                </div>
              ))}
            </div>
          ) : (
            <div className="h-full bg-gradient-to-br from-brand-800 via-slate-900 to-slate-950" />
          )}
          <div className="absolute inset-0 bg-gradient-to-r from-slate-950/90 via-slate-900/75 to-slate-900/55" />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-transparent to-slate-900/40" />
        </div>

        <div className="relative mx-auto flex min-h-[min(88vh,720px)] max-w-6xl flex-col justify-center px-4 py-20">
          <p className="animate-fade-up font-display text-sm font-semibold uppercase tracking-[0.2em] text-brand-300">
            MerchantHub
          </p>
          <h1 className="animate-fade-up animate-delay-100 mt-4 max-w-3xl font-display text-4xl font-semibold leading-tight tracking-tight sm:text-5xl md:text-6xl">
            Local businesses, reviewed with clarity
          </h1>
          <p className="animate-fade-up animate-delay-200 mt-5 max-w-xl text-lg text-slate-200">
            Find neighborhood shops with photos, ratings, and AI-suggested insights — never presented as
            definitive judgments.
          </p>
          <div className="animate-fade-up animate-delay-300 mt-8 max-w-xl">
            <SearchBar className="w-full" placeholder="Try café, salon, pharmacy, Chrompet…" />
            <div className="mt-4 flex flex-wrap gap-3">
              <a
                href="/search"
                className="rounded-lg bg-white px-4 py-2.5 text-sm font-semibold text-slate-900 transition hover:bg-brand-50"
              >
                Explore listings
              </a>
              <a
                href="/register"
                className="rounded-lg border border-white/40 px-4 py-2.5 text-sm font-semibold text-white transition hover:border-white hover:bg-white/10"
              >
                List your business
              </a>
            </div>
          </div>
        </div>
      </section>

      {stats && <TrustMetrics stats={stats} />}

      <CityIndex cities={cityIndex} />

      <CategoryIndex categories={categoryIndex} />

      <FeaturedGrid
        businesses={grid}
        title={featuredCity ? `Explore ${featuredCity}` : "Featured businesses"}
        subtitle="Photos, ratings, and optional AI suggestions drawn from live reviews"
        viewAllHref={featuredCity ? `/search?city=${encodeURIComponent(featuredCity)}` : "/search"}
        viewAllLabel={featuredCity ? `View all in ${featuredCity}` : "View all"}
        loadError={loadError}
      />

      <ReviewVoices items={voiceItems} />

      <section className="mh-section-reveal border-t border-border bg-surface-raised/70 px-4 py-16">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center font-display text-3xl font-semibold tracking-tight text-ink">
            How it works
          </h2>
          <p className="mx-auto mt-2 max-w-xl text-center text-muted">
            Three steps from discovery to supporting the shops around you
          </p>
          <ol className="mt-12 grid gap-10 md:grid-cols-3">
            {[
              {
                n: "01",
                title: "Search",
                body: "Find shops by name, city, or category — with maps and hours when available.",
              },
              {
                n: "02",
                title: "Compare",
                body: "Read ratings and reviews. AI summaries are suggestions to help you scan faster.",
              },
              {
                n: "03",
                title: "Support local",
                body: "Visit, leave feedback, and help independent businesses grow with clearer signal.",
              },
            ].map((step) => (
              <li key={step.n} className="border-t border-brand-200 pt-6">
                <p className="font-display text-sm font-semibold tracking-widest text-brand-700">{step.n}</p>
                <h3 className="mt-3 font-display text-xl font-semibold text-ink">{step.title}</h3>
                <p className="mt-2 text-muted">{step.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="mh-section-reveal relative overflow-hidden bg-brand-900 px-4 py-20 text-white">
        <div
          className="pointer-events-none absolute -right-20 top-0 h-64 w-64 rounded-full bg-brand-500/20 blur-3xl"
          aria-hidden
        />
        <div className="relative mx-auto max-w-6xl">
          <p className="font-display text-sm font-semibold uppercase tracking-[0.18em] text-brand-200">
            For business owners
          </p>
          <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight sm:text-4xl">
            Turn reviews into AI-suggested next steps
          </h2>
          <p className="mt-4 max-w-2xl text-brand-100">
            Claim your listing, reply to customers, and read sentiment suggestions on your dashboard —
            always framed as guidance, not a final verdict.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="/register"
              className="rounded-lg bg-white px-5 py-2.5 text-sm font-semibold text-brand-900 transition hover:bg-brand-50"
            >
              Create a merchant account
            </a>
            <a
              href="/login"
              className="rounded-lg border border-white/35 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-white/10"
            >
              Sign in to dashboard
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
