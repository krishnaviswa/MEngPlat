"use client";

import { useMemo, useState } from "react";
import { ReviewCard } from "./ReviewCard";
import { Select } from "./ui/Select";
import { reviews as reviewsApi } from "@/lib/api";
import type { Review } from "@/lib/api";

interface ReviewsListProps {
  initialReviews: Review[];
}

type SortOption = "newest" | "oldest" | "highest" | "lowest";

const MIN_RATING_OPTIONS = [0, 3, 4, 5] as const;

/** ReviewsList — client wrapper owning like/report state, sort, and min-rating filter for a business's review list. */
export function ReviewsList({ initialReviews }: ReviewsListProps) {
  const [list, setList] = useState(initialReviews);
  const [reportedIds, setReportedIds] = useState<Set<string>>(new Set());
  const [error, setError] = useState("");
  const [sortBy, setSortBy] = useState<SortOption>("newest");
  const [minRating, setMinRating] = useState<number>(0);

  const visible = useMemo(() => {
    const filtered = minRating > 0 ? list.filter((r) => r.rating >= minRating) : list;
    return [...filtered].sort((a, b) => {
      switch (sortBy) {
        case "newest":
          return b.created_at.localeCompare(a.created_at);
        case "oldest":
          return a.created_at.localeCompare(b.created_at);
        case "highest":
          return b.rating - a.rating;
        case "lowest":
          return a.rating - b.rating;
      }
    });
  }, [list, sortBy, minRating]);

  async function handleLike(id: string) {
    setError("");
    setList((prev) => prev.map((r) => (r.id === id ? { ...r, like_count: r.like_count + 1 } : r)));
    try {
      await reviewsApi.like(id);
    } catch (err) {
      setList((prev) => prev.map((r) => (r.id === id ? { ...r, like_count: r.like_count - 1 } : r)));
      setError(err instanceof Error ? err.message : "Couldn't like this review");
    }
  }

  async function handleReport(id: string, reason: string) {
    setError("");
    try {
      await reviewsApi.report(id, reason);
      setReportedIds((prev) => new Set(prev).add(id));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't report this review");
    }
  }

  if (!list.length) {
    return <p className="text-muted">No reviews yet. Be the first!</p>;
  }

  return (
    <div className="space-y-4">
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex flex-wrap gap-2">
          {MIN_RATING_OPTIONS.map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setMinRating(n)}
              className={
                minRating === n
                  ? "rounded-full bg-brand-600 px-3 py-1 text-xs font-medium text-white"
                  : "rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100 dark:bg-brand-900/30 dark:text-brand-300 dark:hover:bg-brand-900/50"
              }
            >
              {n === 0 ? "All" : n === 5 ? "5" : `${n}+`}
            </button>
          ))}
        </div>
        <Select
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value as SortOption)}
          className="ml-auto w-auto"
          aria-label="Sort reviews"
        >
          <option value="newest">Newest</option>
          <option value="oldest">Oldest</option>
          <option value="highest">Highest rating</option>
          <option value="lowest">Lowest rating</option>
        </Select>
      </div>
      {visible.length === 0 ? (
        <div className="rounded-xl border border-border bg-surface p-4 text-center">
          <p className="text-muted">No reviews match these filters.</p>
          <button
            type="button"
            onClick={() => setMinRating(0)}
            className="mt-2 text-sm text-brand-600 hover:text-brand-700"
          >
            Clear filters
          </button>
        </div>
      ) : (
        visible.map((r) =>
          reportedIds.has(r.id) ? (
            <div key={r.id} className="rounded-xl border bg-surface p-4 text-sm text-muted">
              Reported — pending moderation.
            </div>
          ) : (
            <ReviewCard key={r.id} review={r} showActions onLike={handleLike} onReport={handleReport} />
          )
        )
      )}
    </div>
  );
}
