"use client";

import { useCallback, useEffect, useState } from "react";
import { PendingBusinessQueue } from "@/components/admin/PendingBusinessQueue";
import { ReportedReviewsQueue } from "@/components/admin/ReportedReviewsQueue";
import { RequireAuth } from "@/components/RequireAuth";
import { StatCard } from "@/components/ui/StatCard";
import { apiFetch } from "@/lib/api";

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

const STAT_TARGETS: Partial<Record<keyof PlatformStats, string>> = {
  pending_businesses: "pending-businesses",
  reported_reviews: "reported-reviews",
};

function scrollToSection(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

/** Admin moderation panel — platform stats plus pending business and reported review queues. */
export default function AdminPage() {
  const [stats, setStats] = useState<PlatformStats | null>(null);
  const [error, setError] = useState("");

  const loadStats = useCallback(() => {
    apiFetch<PlatformStats>("/api/v1/dashboard/admin/platform")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  useEffect(() => {
    loadStats();
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
              return target ? (
                <button
                  key={key}
                  type="button"
                  onClick={() => scrollToSection(target)}
                  className="rounded-xl border bg-white p-4 text-left transition hover:border-brand-300 hover:shadow-sm"
                >
                  <p className="text-sm text-gray-500">{STAT_LABELS[key]}</p>
                  <p className="text-2xl font-bold">{value}</p>
                </button>
              ) : (
                <StatCard key={key} label={STAT_LABELS[key]} value={value} />
              );
            })}
          </div>
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
      </div>
    </RequireAuth>
  );
}
