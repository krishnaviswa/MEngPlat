"use client";

import { use, useCallback, useEffect, useState } from "react";
import { ReviewCard } from "@/components/ReviewCard";
import { RequireAuth } from "@/components/RequireAuth";
import { businesses, reviews, type Business, type Review } from "@/lib/api";

/** Admin — a single business's shop name plus its full review history (every status). */
export default function AdminBusinessDrilldownPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [business, setBusiness] = useState<Business | null>(null);
  const [reviewList, setReviewList] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      const [allBusinesses, reviewData] = await Promise.all([
        businesses.adminAll({ page_size: 100 }),
        reviews.adminAll({ business_id: id }),
      ]);
      setBusiness(allBusinesses.find((b) => b.id === id) ?? null);
      setReviewList(reviewData);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load business");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        {loading && <p className="text-sm text-gray-500">Loading…</p>}
        {error && <p className="text-sm text-red-600">{error}</p>}
        {!loading && !error && !business && <p className="text-sm text-gray-500">Business not found.</p>}
        {business && (
          <>
            <h1 className="text-2xl font-bold">{business.name}</h1>
            <p className="text-gray-600">{business.city}</p>

            <div className="mt-8">
              <h2 className="mb-3 text-lg font-semibold">Review history</h2>
              {reviewList.length === 0 ? (
                <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
                  No reviews yet
                </p>
              ) : (
                <div className="space-y-4">
                  {reviewList.map((r) => (
                    <ReviewCard key={r.id} review={r} showActions={false} />
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </RequireAuth>
  );
}
