"use client";

import { useCallback, useEffect, useState } from "react";
import { AdminCategoryPanel } from "@/components/admin/AdminCategoryPanel";
import { AdminUserPanel } from "@/components/admin/AdminUserPanel";
import { PendingBusinessQueue } from "@/components/admin/PendingBusinessQueue";
import { ReportedReviewsQueue } from "@/components/admin/ReportedReviewsQueue";
import { Charts } from "@/components/Charts";
import { RequireAuth } from "@/components/RequireAuth";
import { StatCard } from "@/components/ui/StatCard";
import { apiFetch, dashboard, type AdminSeriesBucket, type PlatformAnalyticsSeries } from "@/lib/api";

interface PlatformStats {
  total_users: number;
  total_businesses: number;
  pending_businesses: number;
  total_reviews: number;
  reported_reviews: number;
}

const STAT_LABELS: Record<keyof PlatformStats, string> = {
  total_users: "Total users",
  total_businesses: "Total businesses",
  pending_businesses: "Pending businesses",
  total_reviews: "Total reviews",
  reported_reviews: "Reported reviews",
};

// Same-page scroll targets (existing queue sections further down /admin).
// "Total users" replaces the S-021 static-tile deferral now that user admin exists.
const STAT_TARGETS: Partial<Record<keyof PlatformStats, string>> = {
  total_users: "admin-users",
  pending_businesses: "pending-businesses",
  reported_reviews: "reported-reviews",
};

// Navigate-away targets: "Total businesses"/"Total reviews" browse every
// status, not just the pending/reported subsets covered by STAT_TARGETS.
const STAT_LINKS: Partial<Record<keyof PlatformStats, string>> = {
  total_businesses: "/admin/businesses",
  total_reviews: "/admin/reviews",
};

const SERIES_META: Record<string, { title: string; subtitle?: string }> = {
  new_users: { title: "New users" },
  businesses_approved: {
    title: "Businesses approved",
    subtitle: "Approvals logged (audit events, not current pending count)",
  },
  new_reviews: { title: "New reviews" },
  new_reports: { title: "New reports" },
};

function scrollToSection(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

/** Platform trend chart — dashed empty state (AC 8) when every bucket in the window is zero. */
function SeriesChart({ title, subtitle, data }: { title: string; subtitle?: string; data: AdminSeriesBucket[] }) {
  const allZero = data.every((b) => b.count === 0);
  return (
    <div>
      <h4 className="mb-1 text-sm font-medium text-gray-700">{title}</h4>
      {subtitle && <p className="mb-2 text-xs text-gray-500">{subtitle}</p>}
      {allZero ? (
        <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
          No data yet for this window
        </p>
      ) : (
        <Charts data={data.map((b) => ({ name: b.bucket, value: b.count }))} />
      )}
    </div>
  );
}

/** Admin moderation panel — platform stats, trend charts, category and user admin, and moderation queues. */
export default function AdminPage() {
  const [stats, setStats] = useState<PlatformStats | null>(null);
  const [series, setSeries] = useState<PlatformAnalyticsSeries | null>(null);
  const [error, setError] = useState("");

  const loadStats = useCallback(() => {
    apiFetch<PlatformStats>("/api/v1/dashboard/admin/platform")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  useEffect(() => {
    loadStats();
    dashboard.adminSeries().then(setSeries).catch(() => setSeries(null));
  }, [loadStats]);

  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <h1 className="text-2xl font-bold">Admin Panel</h1>
        <p className="text-gray-600">Platform moderation and analytics</p>

        {error && (
          <div className="mt-6 rounded-lg border border-red-200 bg-red-50 p-4 text-center">
            <p className="text-red-700">{error}</p>
            <p className="mt-2 text-sm text-gray-600">
              Sign in with an admin account to access this page.
            </p>
          </div>
        )}

        {stats && (
          <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {(Object.entries(stats) as [keyof PlatformStats, number][]).map(([key, value]) => {
              const target = STAT_TARGETS[key];
              const link = STAT_LINKS[key];
              if (target) {
                return (
                  <button
                    key={key}
                    type="button"
                    onClick={() => scrollToSection(target)}
                    className="rounded-xl border bg-white p-4 text-left transition hover:border-brand-300 hover:shadow-sm"
                  >
                    <p className="text-sm text-gray-500">{STAT_LABELS[key]}</p>
                    <p className="text-2xl font-bold">{value}</p>
                  </button>
                );
              }
              if (link) {
                return (
                  <a
                    key={key}
                    href={link}
                    className="rounded-xl border bg-white p-4 transition hover:border-brand-300 hover:shadow-sm"
                  >
                    <p className="text-sm text-gray-500">{STAT_LABELS[key]}</p>
                    <p className="text-2xl font-bold">{value}</p>
                  </a>
                );
              }
              return <StatCard key={key} label={STAT_LABELS[key]} value={value} />;
            })}
          </div>
        )}

        {series && (
          <section className="mt-8 rounded-xl border bg-white p-4">
            <h3 className="font-semibold">Platform trends</h3>
            <p className="text-sm text-gray-500">
              Daily counts over the last {series.days} days, from stored timestamps — operational facts, not AI
              output.
            </p>
            <div className="mt-4 grid gap-6 sm:grid-cols-2">
              {Object.entries(SERIES_META).map(([key, meta]) => (
                <SeriesChart key={key} title={meta.title} subtitle={meta.subtitle} data={series.series[key] || []} />
              ))}
            </div>
          </section>
        )}

        <section id="pending-businesses" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Pending businesses</h2>
          <p className="text-sm text-gray-500">Approve new listings or suspend suspicious registrations.</p>
          <div className="mt-4">
            <PendingBusinessQueue onChange={loadStats} />
          </div>
        </section>

        <section id="reported-reviews" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Reported reviews</h2>
          <p className="text-sm text-gray-500">Hide, restore, or permanently remove flagged content.</p>
          <div className="mt-4">
            <ReportedReviewsQueue onChange={loadStats} />
          </div>
        </section>

        <section id="admin-categories" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Categories</h2>
          <p className="text-sm text-gray-500">Add browse categories without a developer.</p>
          <div className="mt-4">
            <AdminCategoryPanel />
          </div>
        </section>

        <section id="admin-users" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Users</h2>
          <p className="text-sm text-gray-500">Suspend or reactivate customer and merchant accounts.</p>
          <div className="mt-4">
            <AdminUserPanel />
          </div>
        </section>
      </div>
    </RequireAuth>
  );
}
