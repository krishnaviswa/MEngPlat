"use client";

import { useCallback, useEffect, useState } from "react";
import { dashboard, type WhatsAppDraft } from "@/lib/api";

const FIELD_LABELS: Record<string, string> = {
  description: "Description",
  address: "Address",
  business_hours: "Hours",
  phone: "Phone",
  website: "Website",
};

/** Pending AI-extracted WhatsApp profile fields — apply/discard only (S-052). */
export function WhatsAppDraftsPanel({ businessId }: { businessId: string }) {
  const [drafts, setDrafts] = useState<WhatsAppDraft[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const rows = await dashboard.listWhatsAppDrafts(businessId);
    setDrafts(rows);
  }, [businessId]);

  useEffect(() => {
    load().catch((err: Error) => setError(err.message));
  }, [load]);

  async function apply(id: string) {
    setBusyId(id);
    setError(null);
    try {
      await dashboard.applyWhatsAppDraft(businessId, id);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Apply failed");
    } finally {
      setBusyId(null);
    }
  }

  async function discard(id: string) {
    setBusyId(id);
    setError(null);
    try {
      await dashboard.discardWhatsAppDraft(businessId, id);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Discard failed");
    } finally {
      setBusyId(null);
    }
  }

  if (drafts.length === 0 && !error) return null;

  return (
    <section className="space-y-3 rounded-xl border border-brand-100 bg-brand-50/50 p-4 dark:border-brand-800/50 dark:bg-brand-900/20">
      <div>
        <h3 className="font-semibold text-brand-900 dark:text-brand-200">Pending WhatsApp updates</h3>
        <p className="text-xs text-brand-700 dark:text-brand-300">
          Suggestions only — not definitive judgments. Nothing goes live until you apply it.
        </p>
      </div>
      {error && <p className="text-sm text-red-700">{error}</p>}
      {drafts.map((draft) => (
        <article key={draft.id} className="rounded-lg border bg-surface-raised p-3">
          {draft.degraded && <p className="mb-2 text-xs text-muted">Mock/degraded data.</p>}
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
          <div className="mt-3 flex gap-2">
            <button
              type="button"
              disabled={busyId === draft.id}
              onClick={() => apply(draft.id)}
              className="rounded-md bg-brand-700 px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50"
            >
              Apply
            </button>
            <button
              type="button"
              disabled={busyId === draft.id}
              onClick={() => discard(draft.id)}
              className="rounded-md border px-3 py-1.5 text-sm font-medium disabled:opacity-50"
            >
              Discard
            </button>
          </div>
        </article>
      ))}
    </section>
  );
}
