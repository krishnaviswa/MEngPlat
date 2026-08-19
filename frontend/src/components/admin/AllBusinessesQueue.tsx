"use client";

import { useCallback, useEffect, useState } from "react";
import { Badge } from "@/components/ui/Badge";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { businesses, type Business, type BusinessStatus } from "@/lib/api";

type Tone = "positive" | "negative" | "neutral";

const STATUS_TONE: Partial<Record<BusinessStatus, Tone>> = {
  approved: "positive",
  pending: "neutral",
  processing: "neutral",
  rejected: "negative",
  suspended: "negative",
};

/** Defensive fallback so an unmapped status (present or future) renders a visible
 * neutral badge instead of a blank/undefined one -- never silently drop a key. */
function statusTone(status: BusinessStatus): Tone {
  return STATUS_TONE[status] ?? "neutral";
}

/** Admin browse — businesses of every status (approved, pending, rejected, suspended). */
export function AllBusinessesQueue() {
  const [items, setItems] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      const list = await businesses.adminAll();
      setItems(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load businesses");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return <p className="text-sm text-muted">Loading businesses…</p>;
  }

  if (error) {
    return <p className="text-sm text-red-600">{error}</p>;
  }

  if (items.length === 0) {
    return (
      <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
        No businesses
      </p>
    );
  }

  return (
    <div className="space-y-3">
      {items.map((b) => (
        <a
          key={b.id}
          href={`/admin/businesses/${b.id}`}
          className="flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-surface-raised p-4 transition hover:border-brand-300 hover:shadow-sm"
        >
          <div>
            <p className="font-semibold">{b.name}</p>
            <p className="text-sm text-muted">{b.city}</p>
          </div>
          <div className="flex shrink-0 items-center gap-3">
            <RatingWidget value={b.average_rating} readonly size="sm" />
            {b.status && <Badge tone={statusTone(b.status)}>{b.status}</Badge>}
          </div>
        </a>
      ))}
    </div>
  );
}
