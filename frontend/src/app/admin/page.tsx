"use client";

import { useCallback, useEffect, useState } from "react";
import { AdminCategoryPanel } from "@/components/admin/AdminCategoryPanel";
import { AdminPaymentPanel } from "@/components/admin/AdminPaymentPanel";
import { AdminUserPanel } from "@/components/admin/AdminUserPanel";
import { PendingBusinessQueue } from "@/components/admin/PendingBusinessQueue";
import { ReportedReviewsQueue } from "@/components/admin/ReportedReviewsQueue";
import { AdminOpsNav } from "@/components/admin/AdminOpsNav";
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
  open_support_tickets: number;
  repeat_shop_reports: number;
  processing_businesses: number;
}

const STAT_LABELS: Record<keyof PlatformStats, string> = {
  total_users: "Total users",
  total_businesses: "Total businesses",
  pending_businesses: "Pending businesses",
  total_reviews: "Total reviews",
  reported_reviews: "Reported reviews",
  open_support_tickets: "Open support tickets",
  repeat_shop_reports: "Repeat shop reports",
  processing_businesses: "Processing businesses",
};

// Same-page scroll targets (existing queue sections further down /admin).
// "Total users" replaces the S-021 static-tile deferral now that user admin exists.
const STAT_TARGETS: Partial<Record<keyof PlatformStats, string>> = {
  total_users: "admin-users",
  pending_businesses: "pending-businesses",
  reported_reviews: "reported-reviews",
  processing_businesses: "pending-businesses",
};

// Navigate-away targets: "Total businesses"/"Total reviews" browse every
// status, not just the pending/reported subsets covered by STAT_TARGETS.
const STAT_LINKS: Partial<Record<keyof PlatformStats, string>> = {
  total_businesses: "/admin/businesses",
  total_reviews: "/admin/reviews",
  open_support_tickets: "/admin/support",
  repeat_shop_reports: "/admin/business-reports",
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
      <h4 className="mb-1 text-sm font-medium text-muted">{title}</h4>
      {/* S-115: always reserve subtitle height so 2×2 chart tops align when only one series has copy. */}
      <div className="mb-2 min-h-[2.5rem]">
        {subtitle ? <p className="text-xs text-muted">{subtitle}</p> : null}
      </div>
      {allZero ? (
        <p className="flex min-h-64 items-center justify-center rounded-lg border border-dashed border-border bg-surface p-6 text-center text-sm text-muted">
          No data yet for this window
        </p>
      ) : (
        <Charts data={data.map((b) => ({ name: b.bucket, value: b.count }))} />
      )}
    </div>
  );
}

/** Admin operational console — ops nav, snapshot tiles, trends, and moderation queues (S-090). */
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
      <div className="mx-auto max-w-6xl px-4 py-8">
        <h1 className="text-2xl font-bold">Admin Panel</h1>
        <p className="text-muted">Operational console — queues, search, and platform facts</p>
        <AdminOpsNav />

        {error && (
          <div className="mt-6 rounded-lg border border-red-200 bg-red-50 p-4 text-center dark:border-red-900/50 dark:bg-red-900/20">
            <p className="text-red-700 dark:text-red-300">{error}</p>
            <p className="mt-2 text-sm text-muted">
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
                    className="rounded-xl border border-border bg-surface-raised p-4 text-left transition hover:border-brand-300 hover:shadow-sm"
                  >
                    <p className="text-sm text-muted">{STAT_LABELS[key]}</p>
                    <p className="text-2xl font-bold">{value}</p>
                  </button>
                );
              }
              if (link) {
                return (
                  <a
                    key={key}
                    href={link}
                    className="rounded-xl border border-border bg-surface-raised p-4 transition hover:border-brand-300 hover:shadow-sm"
                  >
                    <p className="text-sm text-muted">{STAT_LABELS[key]}</p>
                    <p className="text-2xl font-bold">{value}</p>
                  </a>
                );
              }
              return <StatCard key={key} label={STAT_LABELS[key]} value={value} />;
            })}
          </div>
        )}

        {series && (
          <section className="mt-8 rounded-xl border border-border bg-surface-raised p-4">
            <h3 className="font-semibold">Platform trends</h3>
            <p className="text-sm text-muted">
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

        <section id="admin-categories" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Categories</h2>
          <p className="text-sm text-muted">Add browse categories without a developer.</p>
          <div className="mt-4">
            <AdminCategoryPanel />
          </div>
        </section>

        <section id="pending-businesses" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Pending businesses</h2>
          <p className="text-sm text-muted">Approve new listings or suspend suspicious registrations.</p>
          <div className="mt-4">
            <PendingBusinessQueue onChange={loadStats} />
          </div>
        </section>

        <section id="reported-reviews" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Reported reviews</h2>
          <p className="text-sm text-muted">Hide, restore, or permanently remove flagged content.</p>
          <div className="mt-4">
            <ReportedReviewsQueue onChange={loadStats} />
          </div>
        </section>

        <section id="admin-support" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Support</h2>
          <p className="text-sm text-muted">
            Platform contact:{" "}
            <a className="text-brand-600 hover:underline" href="mailto:support@merchanthub.example">
              support@merchanthub.example
            </a>
            . Customer queries and shop reports are separate queues (not review reports).
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <a
              href="/admin/support"
              className="inline-block rounded-lg border border-border bg-surface-raised px-4 py-2 text-sm font-medium transition hover:border-brand-300 hover:shadow-sm"
            >
              Support tickets →
            </a>
            <a
              href="/admin/business-reports"
              className="inline-block rounded-lg border border-border bg-surface-raised px-4 py-2 text-sm font-medium transition hover:border-brand-300 hover:shadow-sm"
            >
              Shop reports →
            </a>
            <a
              href="/support"
              className="inline-block rounded-lg border border-border bg-surface-raised px-4 py-2 text-sm font-medium transition hover:border-brand-300 hover:shadow-sm"
            >
              Public contact page →
            </a>
          </div>
        </section>

        <section id="whatsapp-drafts" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">WhatsApp updates</h2>
          <p className="text-sm text-muted">
            Review AI-extracted profile suggestions submitted by merchants over WhatsApp.
          </p>
          <div className="mt-4">
            <a
              href="/admin/whatsapp"
              className="inline-block rounded-lg border border-border bg-surface-raised px-4 py-2 text-sm font-medium transition hover:border-brand-300 hover:shadow-sm"
            >
              Open review queue →
            </a>
          </div>
        </section>

        <section id="admin-payments" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Payments</h2>
          <p className="text-sm text-muted">
            Featured boost charges. Capture records money; approve turns on search placement. Reject does not
            refund.
          </p>
          <div className="mt-4">
            <AdminPaymentPanel />
          </div>
        </section>

        <section id="admin-users" className="mt-10 scroll-mt-20">
          <h2 className="text-lg font-semibold">Users</h2>
          <p className="text-sm text-muted">
            Suspend or reactivate customer and merchant accounts. Suspend blocks sign-in; reviews and account
            records are kept. There is no delete.
          </p>
          <div className="mt-4">
            <AdminUserPanel />
          </div>
        </section>
      </div>
    </RequireAuth>
  );
}
