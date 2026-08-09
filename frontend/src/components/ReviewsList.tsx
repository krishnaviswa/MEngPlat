"use client";

import { useState } from "react";
import { ReviewCard } from "./ReviewCard";
import { reviews as reviewsApi } from "@/lib/api";
import type { Review } from "@/lib/api";

interface ReviewsListProps {
  initialReviews: Review[];
}

/** ReviewsList — client wrapper owning like/report state for a business's review list. */
export function ReviewsList({ initialReviews }: ReviewsListProps) {
  const [list, setList] = useState(initialReviews);
  const [reportedIds, setReportedIds] = useState<Set<string>>(new Set());
  const [error, setError] = useState("");

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
    return <p className="text-gray-500">No reviews yet. Be the first!</p>;
  }

  return (
    <div className="space-y-4">
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}
      {list.map((r) =>
        reportedIds.has(r.id) ? (
          <div key={r.id} className="rounded-xl border bg-gray-50 p-4 text-sm text-gray-500">
            Reported — pending moderation.
          </div>
        ) : (
          <ReviewCard key={r.id} review={r} showActions onLike={handleLike} onReport={handleReport} />
        )
      )}
    </div>
  );
}
