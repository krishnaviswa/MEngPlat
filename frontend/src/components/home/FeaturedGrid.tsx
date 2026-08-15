import type { Business } from "@/lib/api";
import { BusinessCard } from "@/components/BusinessCard";

interface FeaturedGridProps {
  businesses: Business[];
  title: string;
  subtitle: string;
  viewAllHref: string;
  viewAllLabel: string;
  /** Set when home SSR could not load listings (API unreachable / misconfigured URL). */
  loadError?: string | null;
}

/** FeaturedGrid — interactive listing cards with optional AI suggestion blurbs. */
export function FeaturedGrid({
  businesses,
  title,
  subtitle,
  viewAllHref,
  viewAllLabel,
  loadError = null,
}: FeaturedGridProps) {
  return (
    <section className="mh-section-reveal mx-auto max-w-6xl px-4 py-16">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="max-w-2xl">
          <h2 className="font-display text-3xl font-semibold tracking-tight text-ink">{title}</h2>
          <p className="mt-2 text-muted">{subtitle}</p>
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
                <p className="px-1 text-sm text-muted">
                  <span className="font-medium text-brand-800 dark:text-brand-300">Why locals love it: </span>
                  <span className="line-clamp-2">{b.ai_merchant_summary}</span>
                </p>
              )}
            </div>
          ))}
        </div>
      ) : (
        <div className="mt-8 border border-dashed border-border bg-surface-raised/60 p-6 text-muted">
          {loadError ? (
            <>
              <p className="font-medium text-ink">Could not load businesses from the API.</p>
              <p className="mt-2 text-sm">
                On Railway, set frontend Variables{" "}
                <code className="rounded bg-surface px-1">NEXT_PUBLIC_API_URL</code> and{" "}
                <code className="rounded bg-surface px-1">API_URL_INTERNAL</code> to the backend
                HTTPS URL (no trailing slash), redeploy the frontend, then hard-refresh. Seed is
                run separately in Railway Shell — it does not appear in deploy logs.
              </p>
              <p className="mt-3 font-mono text-xs text-muted break-all">{loadError}</p>
            </>
          ) : (
            <>
              <p className="font-medium text-ink">No businesses loaded yet.</p>
              <p className="mt-2 text-sm">
                If the API is healthy but empty, run seed once in the backend Railway Shell:{" "}
                <code className="rounded bg-surface px-1">
                  PYTHONPATH=/app SEED_MODE=force python scripts/seed.py
                </code>
                . Confirm{" "}
                <code className="rounded bg-surface px-1">GET /api/v1/businesses/cities</code>{" "}
                returns cities, and that{" "}
                <code className="rounded bg-surface px-1">NEXT_PUBLIC_API_URL</code> /{" "}
                <code className="rounded bg-surface px-1">API_URL_INTERNAL</code> point at that
                backend.
              </p>
            </>
          )}
        </div>
      )}
    </section>
  );
}
