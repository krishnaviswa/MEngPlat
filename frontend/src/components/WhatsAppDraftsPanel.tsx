"use client";

import { useCallback, useEffect, useState } from "react";
import { Badge } from "@/components/ui/Badge";
import { dashboard, type WhatsAppDraft } from "@/lib/api";

const FIELD_LABELS: Record<string, string> = {
  description: "Description",
  address: "Address",
  business_hours: "Hours",
  phone: "Phone",
  website: "Website",
};

const STATUS_BADGE: Record<WhatsAppDraft["status"], { label: string; tone: "neutral" | "positive" | "negative" }> = {
  pending: { label: "Pending admin review", tone: "neutral" },
  applied: { label: "Applied", tone: "positive" },
  discarded: { label: "Discarded", tone: "negative" },
};

/**
 * WhatsApp-sourced profile suggestions for this business (S-052/S-053) —
 * read-only. An admin reviews and approves/rejects every suggestion before it
 * can reach the live listing; the merchant can only see the outcome here.
 */
export function WhatsAppDraftsPanel({ businessId }: { businessId: string }) {
  const [drafts, setDrafts] = useState<WhatsAppDraft[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const rows = await dashboard.listWhatsAppDrafts(businessId);
    setDrafts(rows);
  }, [businessId]);

  useEffect(() => {
    load().catch((err: Error) => setError(err.message));
  }, [load]);

  if (drafts.length === 0 && !error) return null;

  return (
    <section className="space-y-3 rounded-xl border border-brand-100 bg-brand-50/50 p-4 dark:border-brand-800/50 dark:bg-brand-900/20">
      <div>
        <h3 className="font-semibold text-brand-900 dark:text-brand-200">WhatsApp updates</h3>
        <p className="text-xs text-brand-700 dark:text-brand-300">
          Suggestions only — not definitive judgments. An admin reviews and approves each one before anything goes
          live.
        </p>
      </div>
      {error && <p className="text-sm text-red-700">{error}</p>}
      {drafts.map((draft) => {
        const badge = STATUS_BADGE[draft.status];
        return (
          <article key={draft.id} className="rounded-lg border bg-surface-raised p-3">
            <div className="mb-2 flex items-center justify-between gap-2">
              <Badge tone={badge.tone}>{badge.label}</Badge>
              {draft.degraded && <p className="text-xs text-muted">Mock/degraded data.</p>}
            </div>
            <ul className="space-y-1 text-sm">
              {Object.entries(draft.extracted_fields)
                .filter(([, value]) => value != null && value !== "")
                .map(([key, value]) => (
                  <li key={key}>
                    <span className="font-medium">{FIELD_LABELS[key] ?? key}</span>
                    <span className="text-muted"> (suggestion): </span>
                    <span>{typeof value === "object" ? JSON.stringify(value) : String(value)}</span>
                  </li>
                ))}
            </ul>
          </article>
        );
      })}
    </section>
  );
}
