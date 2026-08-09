"use client";

import { useCallback, useEffect, useState } from "react";
import { AIInsights } from "./AIInsights";
import { Charts } from "./Charts";
import { Dashboard } from "./Dashboard";
import { ReviewCard } from "./ReviewCard";
import { auth, businesses, dashboard, reviews as reviewsApi } from "@/lib/api";
import type { Business, BusinessStatus, Review, User } from "@/lib/api";

const STATUS_LABEL: Record<BusinessStatus, string> = {
  pending: "Awaiting approval",
  approved: "Active",
  rejected: "Rejected",
  suspended: "Suspended",
};

const STATUS_CLASS: Record<BusinessStatus, string> = {
  pending: "text-amber-600",
  approved: "text-green-600",
  rejected: "text-gray-600",
  suspended: "text-red-600",
};

/** MerchantDashboard — stats, charts, AI insights, recent reviews for owned businesses. */
export default function MerchantDashboardPage() {
  const [owned, setOwned] = useState<Business[]>([]);
  const [selectedId, setSelectedId] = useState<string>("");
  const [business, setBusiness] = useState<Business | null>(null);
  const [stats, setStats] = useState<Record<string, unknown> | null>(null);
  const [insights, setInsights] = useState<Record<string, unknown> | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshingAi, setRefreshingAi] = useState(false);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    auth.me().then(setUser).catch(() => setUser(null));
  }, []);

  useEffect(() => {
    businesses
      .mine()
      .then((list) => {
        setOwned(list);
        if (list.length > 0) setSelectedId(list[0].id);
      })
      .catch(() => setOwned([]))
      .finally(() => setLoading(false));
  }, []);

  const loadDashboard = useCallback(async (b: Business) => {
    setBusiness(b);
    const [dash, ins] = await Promise.all([
      dashboard.merchant(b.id),
      dashboard.insights(b.id),
    ]);
    setStats(dash);
    setInsights(ins);
  }, []);

  useEffect(() => {
    if (!selectedId) return;
    const b = owned.find((x) => x.id === selectedId);
    if (!b) return;
    loadDashboard(b).catch(() => {
      setStats(null);
      setInsights(null);
    });
  }, [selectedId, owned, loadDashboard]);

  async function handleReply(reviewId: string, body: string) {
    const reply = await reviewsApi.reply(reviewId, body);
    setStats((prev) => {
      if (!prev) return prev;
      const recent = (prev.recent_reviews as Review[]) || [];
      return { ...prev, recent_reviews: recent.map((r) => (r.id === reviewId ? { ...r, reply } : r)) };
    });
  }

  async function handleRefreshAi() {
    if (!business) return;
    setRefreshingAi(true);
    try {
      const ins = await dashboard.refreshInsights(business.id);
      setInsights(ins);
    } finally {
      setRefreshingAi(false);
    }
  }

  const navItems = [
    { href: "/merchant/dashboard", label: "Overview" },
    ...(business
      ? [
          { href: `/merchant/businesses/${business.id}/edit`, label: "Edit business" },
          { href: `/businesses/${business.slug}`, label: "Public profile" },
        ]
      : []),
    { href: "/merchant/businesses/new", label: "Add business" },
    { href: "/settings", label: "Settings" },
  ];

  if (loading) return <p className="p-8 text-center">Loading dashboard...</p>;

  if (owned.length === 0) {
    return (
      <Dashboard title="Merchant Dashboard" description="Manage your business" navItems={navItems}>
        <div className="rounded-xl border bg-white p-8 text-center">
          <h2 className="text-lg font-semibold text-gray-900">No business yet</h2>
          <p className="mt-2 text-sm text-gray-600">
            Register your shop or service to see reviews, stats, and AI insights here.
          </p>
          <a
            href="/merchant/businesses/new"
            className="mt-4 inline-block rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700"
          >
            Create your business
          </a>
        </div>
      </Dashboard>
    );
  }

  if (!business) return <p className="p-8 text-center">Loading dashboard...</p>;

  const status = (business.status ?? "approved") as BusinessStatus;
  const sentimentData = stats?.sentiment_breakdown
    ? Object.entries(stats.sentiment_breakdown as Record<string, number>).map(([name, value]) => ({
        name: name.charAt(0).toUpperCase() + name.slice(1),
        value,
      }))
    : [];

  return (
    <Dashboard title="Merchant Dashboard" description={business.name} navItems={navItems}>
      <div className="space-y-6">
        {owned.length > 1 && (
          <label className="block rounded-xl border bg-white p-4">
            <span className="text-sm font-medium text-gray-700">Your businesses</span>
            <select
              value={selectedId}
              onChange={(e) => setSelectedId(e.target.value)}
              className="mt-2 w-full rounded border px-3 py-2 sm:max-w-md"
            >
              {owned.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                  {b.status === "pending" ? " (pending)" : ""}
                </option>
              ))}
            </select>
          </label>
        )}

        {status === "pending" && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            Your business is <strong>awaiting admin approval</strong>. You can update details anytime; public
            discovery starts after approval.
          </div>
        )}

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
            <p className={`text-2xl font-bold ${STATUS_CLASS[status]}`}>{STATUS_LABEL[status]}</p>
          </div>
        </div>

        <div className="rounded-xl border bg-white p-4">
          <h3 className="font-semibold">Sentiment breakdown</h3>
          <Charts data={sentimentData} />
        </div>

        {insights && (
          <div className="space-y-3">
            <div className="flex items-center justify-between gap-3">
              <p className="text-sm text-gray-600">Refresh AI summary when you want an updated suggestion.</p>
              <button
                type="button"
                onClick={handleRefreshAi}
                disabled={refreshingAi}
                className="rounded border border-brand-300 bg-white px-3 py-1.5 text-sm text-brand-700 hover:bg-brand-50 disabled:opacity-50"
              >
                {refreshingAi ? "Refreshing..." : "Refresh AI insights"}
              </button>
            </div>
            <AIInsights insights={insights as Parameters<typeof AIInsights>[0]["insights"]} />
          </div>
        )}

        <div>
          <h3 className="mb-3 font-semibold">Recent reviews</h3>
          <div className="space-y-3">
            {((stats?.recent_reviews as Review[]) || []).length === 0 ? (
              <p className="text-sm text-gray-500">No reviews yet.</p>
            ) : (
              ((stats?.recent_reviews as Review[]) || []).map((r) => (
                <ReviewCard
                  key={r.id}
                  review={r}
                  showActions={false}
                  canReply={user?.role === "merchant"}
                  onReply={handleReply}
                />
              ))
            )}
          </div>
        </div>
      </div>
    </Dashboard>
  );
}
