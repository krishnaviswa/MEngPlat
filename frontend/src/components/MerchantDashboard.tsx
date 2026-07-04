"use client";

import { useEffect, useState } from "react";
import { AIInsights } from "./AIInsights";
import { Charts } from "./Charts";
import { Dashboard } from "./Dashboard";
import { ReviewCard } from "./ReviewCard";
import { businesses, dashboard } from "@/lib/api";
import type { Business, Review } from "@/lib/api";

/** MerchantDashboard — stats, charts, AI insights, recent reviews. */
export default function MerchantDashboardPage() {
  const [business, setBusiness] = useState<Business | null>(null);
  const [stats, setStats] = useState<Record<string, unknown> | null>(null);
  const [insights, setInsights] = useState<Record<string, unknown> | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const list = await businesses.list();
        const b = list[0];
        if (!b) return;
        setBusiness(b);
        const [dash, ins] = await Promise.all([
          dashboard.merchant(b.id),
          dashboard.insights(b.id),
        ]);
        setStats(dash);
        setInsights(ins);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) return <p className="p-8 text-center">Loading dashboard...</p>;
  if (!business) return <p className="p-8 text-center">No business found. Register one first.</p>;

  const sentimentData = stats?.sentiment_breakdown
    ? Object.entries(stats.sentiment_breakdown as Record<string, number>).map(([name, value]) => ({
        name: name.charAt(0).toUpperCase() + name.slice(1),
        value,
      }))
    : [];

  return (
    <Dashboard
      title="Merchant Dashboard"
      description={business.name}
      navItems={[
        { href: "/merchant/dashboard", label: "Overview" },
        { href: `/businesses/${business.slug}`, label: "Public profile" },
        { href: "/settings", label: "Settings" },
      ]}
    >
      <div className="space-y-6">
        <div className="grid gap-4 sm:grid-cols-3">
          <div className="rounded-xl border bg-white p-4">
            <p className="text-sm text-gray-500">Total reviews</p>
            <p className="text-2xl font-bold">{String(stats?.total_reviews ?? 0)}</p>
          </div>
          <div className="rounded-xl border bg-white p-4">
            <p className="text-sm text-gray-500">Average rating</p>
            <p className="text-2xl font-bold">{Number(stats?.average_rating ?? 0).toFixed(1)}</p>
          </div>
          <div className="rounded-xl border bg-white p-4">
            <p className="text-sm text-gray-500">Status</p>
            <p className="text-2xl font-bold text-green-600">Active</p>
          </div>
        </div>
        <div className="rounded-xl border bg-white p-4">
          <h3 className="font-semibold">Sentiment breakdown</h3>
          <Charts data={sentimentData} />
        </div>
        {insights && <AIInsights insights={insights as Parameters<typeof AIInsights>[0]["insights"]} />}
        <div>
          <h3 className="mb-3 font-semibold">Recent reviews</h3>
          <div className="space-y-3">
            {((stats?.recent_reviews as Review[]) || []).map((r) => (
              <ReviewCard key={r.id} review={r} showActions={false} />
            ))}
          </div>
        </div>
      </div>
    </Dashboard>
  );
}
