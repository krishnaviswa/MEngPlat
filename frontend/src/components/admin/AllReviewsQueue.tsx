"use client";

import { useCallback, useEffect, useState } from "react";
import { ReviewCard } from "@/components/ReviewCard";
import { reviews, type Review } from "@/lib/api";

/** Admin browse — reviews across every business and status, no moderation actions. */
export function AllReviewsQueue() {
  const [items, setItems] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      const list = await reviews.adminAll();
      setItems(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load reviews");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return <p className="text-sm text-gray-500">Loading reviews…</p>;
  }

  if (error) {
    return <p className="text-sm text-red-600">{error}</p>;
  }

  if (items.length === 0) {
    return (
      <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
        No reviews
      </p>
    );
  }

  return (
    <div className="space-y-4">
      {items.map((r) => (
        <ReviewCard key={r.id} review={r} showActions={false} showBusinessLink />
      ))}
    </div>
  );
}
