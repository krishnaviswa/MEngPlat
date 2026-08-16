"use client";

import { useCallback, useEffect, useState } from "react";
import { AIInsights } from "./AIInsights";
import { Charts } from "./Charts";
import { Dashboard } from "./Dashboard";
import { GooglePlacePicker } from "./GooglePlacePicker";
import { ReviewCard } from "./ReviewCard";
import { FeaturedBoostPanel } from "./FeaturedBoostPanel";
import { MerchantNationalIdCard } from "./MerchantNationalIdCard";
import { CollectQrCard } from "./CollectQrCard";
import { BenchmarkCard } from "./BenchmarkCard";
import { Select } from "./ui/Select";
import { StatCard } from "./ui/StatCard";
import { auth, businesses, dashboard, reviews as reviewsApi } from "@/lib/api";
import type { Business, BusinessStatus, DashboardRange, GoogleReviewsStatus, Review, User } from "@/lib/api";

const RANGE_LABEL: Record<DashboardRange, string> = {
  "30": "Last 30 days",
  "90": "Last 90 days",
  all: "All time",
};

const RATING_STARS = ["1", "2", "3", "4", "5"] as const;

const STATUS_LABEL: Record<BusinessStatus, string> = {
  pending: "Awaiting approval",
  approved: "Active",
  rejected: "Rejected",
  suspended: "Suspended",
};

const STATUS_CLASS: Record<BusinessStatus, string> = {
  pending: "text-amber-600 dark:text-amber-400",
  approved: "text-green-600 dark:text-green-400",
  rejected: "text-muted",
  suspended: "text-red-600 dark:text-red-400",
};

function scrollToSection(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

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
  const [range, setRange] = useState<DashboardRange>("all");
  const [exportingCsv, setExportingCsv] = useState(false);
  const [benchmark, setBenchmark] = useState<{
    own_rating: number;
    category_median: number | null;
    city_median: number | null;
    disclaimer: string;
  } | null>(null);
  const [googleStatus, setGoogleStatus] = useState<GoogleReviewsStatus | null>(null);
  const [showGooglePicker, setShowGooglePicker] = useState(false);
  const [syncingGoogle, setSyncingGoogle] = useState(false);
  const [googleError, setGoogleError] = useState<string | null>(null);

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

  const loadBusiness = useCallback(async (b: Business) => {
    setBusiness(b);
    const ins = await dashboard.insights(b.id);
    const topics = await dashboard.topics(b.id).catch(() => null);
    setInsights({
      ...ins,
      ...(topics && {
        topics: topics.topics,
        topics_degraded: topics.degraded,
        topics_insufficient_data: topics.insufficient_data,
        topics_unavailable: topics.unavailable,
      }),
    });
  }, []);

  useEffect(() => {
    if (!selectedId) return;
    const b = owned.find((x) => x.id === selectedId);
    if (!b) return;
    loadBusiness(b).catch(() => setInsights(null));
  }, [selectedId, owned, loadBusiness]);

  useEffect(() => {
    if (!business) return;
    dashboard
      .merchant(business.id, { range })
      .then(setStats)
      .catch(() => setStats(null));
  }, [business, range]);

  useEffect(() => {
    if (!business) return;
    dashboard
      .benchmark(business.id)
      .then(setBenchmark)
      .catch(() => setBenchmark(null));
  }, [business]);

  useEffect(() => {
    if (!business) return;
    setShowGooglePicker(false);
    setGoogleError(null);
    dashboard
      .getGoogleReviewsStatus(business.id)
      .then(setGoogleStatus)
      .catch(() => setGoogleStatus(null));
  }, [business]);

  async function handleExportCsv() {
    if (!business) return;
    setExportingCsv(true);
    try {
      const blob = await dashboard.reviewsCsv(business.id, { range });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `reviews-${business.id}-${range}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } finally {
      setExportingCsv(false);
    }
  }

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

  async function handleGoogleLinked() {
    if (!business) return;
    setShowGooglePicker(false);
    const status = await dashboard.getGoogleReviewsStatus(business.id).catch(() => null);
    setGoogleStatus(status);
  }

  async function handleSyncGoogleReviews() {
    if (!business) return;
    setSyncingGoogle(true);
    setGoogleError(null);
    try {
      await dashboard.syncGoogleReviews(business.id);
      const status = await dashboard.getGoogleReviewsStatus(business.id);
      setGoogleStatus(status);
    } catch (err) {
      // AC5's "leave existing state untouched" principle applied to sync too.
      setGoogleError(err instanceof Error ? err.message : "Couldn't sync Google reviews right now");
    } finally {
      setSyncingGoogle(false);
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
        <div className="space-y-6">
          {user?.role === "merchant" && <MerchantNationalIdCard user={user} onSaved={setUser} />}
          <div className="rounded-xl border bg-surface-raised p-8 text-center">
            <h2 className="text-lg font-semibold text-ink">No business yet</h2>
            <p className="mt-2 text-sm text-muted">
              Register your shop or service to see reviews, stats, and AI insights here.
            </p>
            <a
              href="/merchant/businesses/new"
              className="mt-4 inline-block rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700"
            >
              Create your business
            </a>
          </div>
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
  const volumeData = ((stats?.review_volume_by_month as { month: string; count: number }[] | undefined) || []).map(
    (v) => ({ name: v.month, value: v.count })
  );
  const ratingDistribution = (stats?.rating_distribution as Record<string, number> | undefined) || {};
  const ratingData = RATING_STARS.map((star) => ({ name: `${star}★`, value: ratingDistribution[star] ?? 0 }));
  const inRangeReviewCount = ratingData.reduce((sum, r) => sum + r.value, 0);
  const replyRate = stats?.reply_rate as number | null | undefined;
  const replyPrev = stats?.reply_rate_previous as number | null | undefined;
  const countInRange = stats?.review_count_in_range as number | null | undefined;
  const countPrev = stats?.review_count_previous as number | null | undefined;

  function deltaText(current: number | null | undefined, previous: number | null | undefined): string {
    if (range === "all" || current == null || previous == null || previous === 0) return "n/a";
    const pct = Math.round(((current - previous) / previous) * 100);
    return `${pct > 0 ? "+" : ""}${pct}% vs prior period`;
  }

  return (
    <Dashboard title="Merchant Dashboard" description={business.name} navItems={navItems}>
      <div className="space-y-6">
        {owned.length > 1 && (
          <label className="block rounded-xl border bg-surface-raised p-4">
            <span className="text-sm font-medium text-muted">Your businesses</span>
            <Select
              value={selectedId}
              onChange={(e) => setSelectedId(e.target.value)}
              className="mt-2 sm:max-w-md"
            >
              {owned.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                  {b.status === "pending" ? " (pending)" : ""}
                </option>
              ))}
            </Select>
          </label>
        )}

        {status === "pending" && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-800/50 dark:bg-amber-900/20 dark:text-amber-300">
            Your business is <strong>awaiting admin approval</strong>. You can update details anytime; public
            discovery starts after approval.
          </div>
        )}

        <div className="grid gap-4 sm:grid-cols-3">
          <button
            type="button"
            onClick={() => scrollToSection("recent-reviews")}
            className="rounded-xl border bg-surface-raised p-4 text-left transition hover:border-brand-300 hover:shadow-sm"
          >
            <p className="text-sm text-muted">Total reviews</p>
            <p className="text-2xl font-bold">{String(stats?.total_reviews ?? 0)}</p>
          </button>
          <button
            type="button"
            onClick={() => scrollToSection("sentiment-breakdown")}
            className="rounded-xl border bg-surface-raised p-4 text-left transition hover:border-brand-300 hover:shadow-sm"
          >
            <p className="text-sm text-muted">Average rating</p>
            <p className="text-2xl font-bold">{Number(stats?.average_rating ?? 0).toFixed(1)}</p>
          </button>
          <a
            href={status === "approved" ? `/businesses/${business.slug}` : `/merchant/businesses/${business.id}/edit`}
            className="rounded-xl border bg-surface-raised p-4 transition hover:border-brand-300 hover:shadow-sm"
          >
            <p className="text-sm text-muted">Status</p>
            <p className={`text-2xl font-bold ${STATUS_CLASS[status]}`}>{STATUS_LABEL[status]}</p>
          </a>
        </div>

        {user?.role === "merchant" && (
          <MerchantNationalIdCard user={user} onSaved={setUser} />
        )}
        <FeaturedBoostPanel businessId={business.id} listingStatus={status} />
        {status === "approved" && <CollectQrCard businessId={business.id} businessName={business.name} />}

        <div id="review-analytics" className="scroll-mt-20 rounded-xl border bg-surface-raised p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h3 className="font-semibold">Review analytics</h3>
            <div className="flex items-center gap-3">
              <Select
                value={range}
                onChange={(e) => setRange(e.target.value as DashboardRange)}
                className="w-auto"
                aria-label="Date range"
              >
                {(Object.keys(RANGE_LABEL) as DashboardRange[]).map((r) => (
                  <option key={r} value={r}>
                    {RANGE_LABEL[r]}
                  </option>
                ))}
              </Select>
              <button
                type="button"
                onClick={handleExportCsv}
                disabled={exportingCsv}
                className="rounded border border-brand-300 bg-surface-raised px-3 py-1.5 text-sm text-brand-700 hover:bg-brand-50 disabled:opacity-50"
              >
                {exportingCsv ? "Exporting..." : "Export CSV"}
              </button>
            </div>
          </div>

          <div className="mt-4 grid gap-6 sm:grid-cols-2">
            <div>
              <h4 className="mb-2 text-sm font-medium text-muted">Review volume</h4>
              <Charts data={volumeData} variant="area" emptyMessage="No reviews in this range yet." />
            </div>
            <div>
              <h4 className="mb-2 text-sm font-medium text-muted">Rating mix (1-5 stars)</h4>
              <Charts data={ratingData} emptyMessage="No reviews in this range yet." />
            </div>
          </div>

          {inRangeReviewCount === 0 && (
            <p className="mt-3 text-sm text-muted">
              No reviews in this range yet. Try a wider date range, or check back once customers start reviewing.
            </p>
          )}

          <div className="mt-4 max-w-xs">
            <StatCard
              label="Reply rate"
              value={replyRate == null ? "—" : `${Math.round(replyRate * 100)}%`}
              trend={
                replyRate == null
                  ? "No reviews in this range"
                  : `${RANGE_LABEL[range]} · ${deltaText(replyRate, replyPrev)}`
              }
            />
            <StatCard
              label="Reviews in range"
              value={countInRange ?? "—"}
              trend={deltaText(countInRange, countPrev)}
            />
          </div>
        </div>

        {benchmark && (
          <BenchmarkCard
            own={benchmark.own_rating}
            categoryMedian={benchmark.category_median}
            cityMedian={benchmark.city_median}
            disclaimer={benchmark.disclaimer}
          />
        )}

        <div id="sentiment-breakdown" className="scroll-mt-20 rounded-xl border bg-surface-raised p-4">
          <h3 className="font-semibold">Sentiment breakdown</h3>
          <Charts data={sentimentData} />
        </div>

        <div className="rounded-xl border bg-surface-raised p-4">
          <h3 className="font-semibold">Google reviews</h3>
          <p className="mt-1 text-sm text-muted">
            Showing up to 5 most-relevant Google reviews on your public profile -- not a full review history.
          </p>

          {!googleStatus?.linked ? (
            <div className="mt-3">
              {!showGooglePicker ? (
                <>
                  <p className="text-sm text-muted">Link your Google Business Profile to sync reviews.</p>
                  <button
                    type="button"
                    onClick={() => setShowGooglePicker(true)}
                    className="mt-2 rounded border border-brand-300 bg-surface-raised px-3 py-1.5 text-sm text-brand-700 hover:bg-brand-50"
                  >
                    Link Google Business Profile
                  </button>
                </>
              ) : (
                <div className="mt-2">
                  <GooglePlacePicker
                    businessId={business.id}
                    businessName={business.name}
                    center={business.latitude != null && business.longitude != null ? [business.latitude, business.longitude] : null}
                    onLinked={handleGoogleLinked}
                  />
                </div>
              )}
            </div>
          ) : (
            <div className="mt-3 flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm text-ink">
                  {googleStatus.review_count > 0
                    ? `${googleStatus.review_count} review${googleStatus.review_count === 1 ? "" : "s"} synced`
                    : "Linked -- not yet synced"}
                </p>
                {googleStatus.last_synced_at && (
                  <p className="text-xs text-muted">
                    Last synced {new Date(googleStatus.last_synced_at).toLocaleString()}
                  </p>
                )}
              </div>
              <button
                type="button"
                onClick={handleSyncGoogleReviews}
                disabled={syncingGoogle}
                className="rounded border border-brand-300 bg-surface-raised px-3 py-1.5 text-sm text-brand-700 hover:bg-brand-50 disabled:opacity-50"
              >
                {syncingGoogle ? "Syncing..." : "Sync now"}
              </button>
            </div>
          )}

          {googleError && (
            <p role="alert" className="mt-2 text-sm text-red-600 dark:text-red-400">
              {googleError}
            </p>
          )}
        </div>

        {insights && (
          <div className="space-y-3">
            <div className="flex items-center justify-between gap-3">
              <p className="text-sm text-muted">Refresh AI summary when you want an updated suggestion.</p>
              <button
                type="button"
                onClick={handleRefreshAi}
                disabled={refreshingAi}
                className="rounded border border-brand-300 bg-surface-raised px-3 py-1.5 text-sm text-brand-700 hover:bg-brand-50 disabled:opacity-50"
              >
                {refreshingAi ? "Refreshing..." : "Refresh AI insights"}
              </button>
            </div>
            <AIInsights insights={insights as Parameters<typeof AIInsights>[0]["insights"]} />
          </div>
        )}

        <div id="recent-reviews" className="scroll-mt-20">
          <h3 className="mb-3 font-semibold">Recent reviews</h3>
          <div className="space-y-3">
            {((stats?.recent_reviews as Review[]) || []).length === 0 ? (
              <p className="text-sm text-muted">No reviews yet.</p>
            ) : (
              ((stats?.recent_reviews as Review[]) || []).map((r) => (
                <ReviewCard
                  key={r.id}
                  review={r}
                  showActions={false}
                  showSentimentBadge
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
