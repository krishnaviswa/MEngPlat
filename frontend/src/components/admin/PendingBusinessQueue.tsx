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
      const list = await businesses.list({ status_filter: "pending" });
      setItems(list);
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

  if (loading) {
    return <p className="text-sm text-gray-500">Loading pending businesses…</p>;
  }

  return (
    <div className="space-y-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
          No pending businesses
        </p>
      ) : (
        items.map((b) => (
          <div key={b.id} className="flex flex-wrap items-start justify-between gap-3 rounded-xl border bg-white p-4">
            <div>
              <p className="font-semibold">{b.name}</p>
              <p className="text-sm text-gray-600">
                {b.address}, {b.city}
              </p>
              {b.description && <p className="mt-1 text-sm text-gray-500 line-clamp-2">{b.description}</p>}
            </div>
            <div className="flex shrink-0 gap-2">
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
                className="rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 disabled:opacity-50"
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
