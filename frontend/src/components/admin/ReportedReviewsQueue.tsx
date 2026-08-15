"use client";

import { useCallback, useEffect, useState } from "react";
import { ReviewCard } from "@/components/ReviewCard";
import { reviews, type Review } from "@/lib/api";

type ModerateAction = "hide" | "restore" | "remove";

/** Admin queue — reported reviews with hide / restore / remove actions. */
export function ReportedReviewsQueue({ onChange }: { onChange?: () => void }) {
  const [items, setItems] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError("");
    try {
      const list = await reviews.reported();
      setItems(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load reported reviews");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function handleModerate(id: string, action: ModerateAction) {
    setActing(id);
    try {
      await reviews.moderate(id, action);
      setItems((prev) => prev.filter((r) => r.id !== id));
      onChange?.();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Moderation failed");
    } finally {
      setActing(null);
    }
  }

  if (loading) {
    return <p className="text-sm text-muted">Loading reported reviews…</p>;
  }

  return (
    <div className="space-y-4">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No reported reviews
        </p>
      ) : (
        items.map((r) => (
          <div key={r.id} className="space-y-2">
            <ReviewCard review={r} showActions={false} showBusinessLink showSentimentBadge />
            <div className="flex flex-wrap gap-2 pl-1">
              <button
                type="button"
                disabled={acting === r.id}
                onClick={() => handleModerate(r.id, "hide")}
                className="rounded-lg bg-amber-600 px-3 py-1.5 text-sm text-white hover:bg-amber-700 disabled:opacity-50"
              >
                Hide
              </button>
              <button
                type="button"
                disabled={acting === r.id}
                onClick={() => handleModerate(r.id, "restore")}
                className="rounded-lg border px-3 py-1.5 text-sm hover:bg-surface disabled:opacity-50"
              >
                Restore
              </button>
              <button
                type="button"
                disabled={acting === r.id}
                onClick={() => handleModerate(r.id, "remove")}
                className="rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/30 disabled:opacity-50"
              >
                Remove
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  );
}
