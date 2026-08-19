"use client";

import { useCallback, useEffect, useState } from "react";
import { businesses, type Business } from "@/lib/api";

/** Admin queue — pending business registrations awaiting approve/suspend. */
export function PendingBusinessQueue({ onChange }: { onChange?: () => void }) {
  const [items, setItems] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError("");
    try {
      const [pending, processing] = await Promise.all([
        businesses.list({ status_filter: "pending" }),
        businesses.list({ status_filter: "processing" }),
      ]);
      setItems([...pending, ...processing]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load pending businesses");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function handleApprove(id: string) {
    setActing(id);
    try {
      await businesses.approve(id);
      setItems((prev) => prev.filter((b) => b.id !== id));
      onChange?.();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Approve failed");
    } finally {
      setActing(null);
    }
  }

  async function handleSuspend(id: string) {
    setActing(id);
    try {
      await businesses.suspend(id);
      setItems((prev) => prev.filter((b) => b.id !== id));
      onChange?.();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Suspend failed");
    } finally {
      setActing(null);
    }
  }

  async function handleStartReview(id: string) {
    setActing(id);
    try {
      const updated = await businesses.startReview(id);
      setItems((prev) => prev.map((b) => (b.id === id ? updated : b)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Start review failed");
    } finally {
      setActing(null);
    }
  }

  async function handleReturnToPending(id: string) {
    setActing(id);
    try {
      const updated = await businesses.returnToPending(id);
      setItems((prev) => prev.map((b) => (b.id === id ? updated : b)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Return to pending failed");
    } finally {
      setActing(null);
    }
  }

  if (loading) {
    return <p className="text-sm text-muted">Loading pending businesses…</p>;
  }

  return (
    <div className="space-y-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No businesses awaiting review
        </p>
      ) : (
        items.map((b) => (
          <div key={b.id} className="flex flex-wrap items-start justify-between gap-3 rounded-xl border bg-surface-raised p-4">
            <div>
              <div className="flex items-center gap-2">
                <p className="font-semibold">{b.name}</p>
                {b.status === "processing" && (
                  <span className="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900/40 dark:text-blue-300">
                    Processing
                  </span>
                )}
              </div>
              <p className="text-sm text-muted">
                {b.address}, {b.city}
              </p>
              {b.description && <p className="mt-1 text-sm text-muted line-clamp-2">{b.description}</p>}
            </div>
            <div className="flex shrink-0 gap-2">
              {b.status === "pending" && (
                <button
                  type="button"
                  disabled={acting === b.id}
                  onClick={() => handleStartReview(b.id)}
                  className="rounded-lg border px-3 py-1.5 text-sm hover:bg-surface disabled:opacity-50"
                >
                  Start review
                </button>
              )}
              {b.status === "processing" && (
                <button
                  type="button"
                  disabled={acting === b.id}
                  onClick={() => handleReturnToPending(b.id)}
                  className="rounded-lg border px-3 py-1.5 text-sm hover:bg-surface disabled:opacity-50"
                >
                  Return to pending
                </button>
              )}
              <button
                type="button"
                disabled={acting === b.id}
                onClick={() => handleApprove(b.id)}
                className="rounded-lg bg-green-600 px-3 py-1.5 text-sm text-white hover:bg-green-700 disabled:opacity-50"
              >
                Approve
              </button>
              <button
                type="button"
                disabled={acting === b.id}
                onClick={() => handleSuspend(b.id)}
                className="rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/30 disabled:opacity-50"
              >
                Suspend
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  );
}
