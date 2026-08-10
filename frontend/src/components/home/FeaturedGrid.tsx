import type { Business } from "@/lib/api";
import { BusinessCard } from "@/components/BusinessCard";

interface FeaturedGridProps {
  businesses: Business[];
  title: string;
  subtitle: string;
  viewAllHref: string;
  viewAllLabel: string;
}

/** FeaturedGrid — interactive listing cards with optional AI suggestion blurbs. */
export function FeaturedGrid({
  businesses,
  title,
  subtitle,
  viewAllHref,
  viewAllLabel,
}: FeaturedGridProps) {
  return (
    <section className="mh-section-reveal mx-auto max-w-6xl px-4 py-16">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="max-w-2xl">
          <h2 className="font-display text-3xl font-semibold tracking-tight text-slate-900">{title}</h2>
          <p className="mt-2 text-slate-600">{subtitle}</p>
        </div>
        <a href={viewAllHref} className="text-sm font-medium text-brand-700 hover:underline">
          {viewAllLabel} →
        </a>
      </div>

      {businesses.length > 0 ? (
        <div className="mt-10 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {businesses.map((b) => (
            <div key={b.id} className="flex flex-col gap-3">
              <BusinessCard business={b} />
              {b.ai_merchant_summary && (
                <p className="px-1 text-sm text-slate-600">
                  <span className="font-medium text-brand-800">AI suggestion: </span>
                  <span className="line-clamp-2">{b.ai_merchant_summary}</span>
                </p>
              )}
            </div>
          ))}
        </div>
      ) : (
        <p className="mt-8 border border-dashed border-slate-300 bg-white/60 p-6 text-slate-600">
          No businesses loaded yet. On Railway, confirm the backend deploy log shows{" "}
          <code className="rounded bg-slate-100 px-1">Seed complete</code> with Chrompet counts, that{" "}
          <code className="rounded bg-slate-100 px-1">NEXT_PUBLIC_API_URL</code> and{" "}
          <code className="rounded bg-slate-100 px-1">API_URL_INTERNAL</code> point at the backend HTTPS
          URL, then redeploy the frontend and refresh.
        </p>
      )}
    </section>
  );
}
