"use client";

import { useCallback, useEffect, useState } from "react";
import { admin, type AdminWhatsAppDraft } from "@/lib/api";

const FIELD_LABELS: Record<string, string> = {
  description: "Description",
  address: "Address",
  business_hours: "Hours",
  phone: "Phone",
  website: "Website",
};

// business_hours is a structured object, not free text -- shown for context,
// not directly editable in this queue (approve falls back to the AI value).
const EDITABLE_FIELDS = ["description", "address", "phone", "website"] as const;

const PAGE_SIZE = 20;

function formatValue(value: unknown): string {
  if (value == null || value === "") return "";
  return typeof value === "object" ? JSON.stringify(value) : String(value);
}

/** Admin queue — every pending WhatsApp-derived profile suggestion, across all businesses (S-053). */
export function AdminWhatsAppDraftsQueue() {
  const [items, setItems] = useState<AdminWhatsAppDraft[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);
  const [edits, setEdits] = useState<Record<string, Record<string, string>>>({});

  const load = useCallback(async (targetPage: number) => {
    setLoading(true);
    setError("");
    try {
      const queue = await admin.whatsappDrafts({ page: targetPage, page_size: PAGE_SIZE });
      setItems(queue.items);
      setTotal(queue.total);
      setPage(queue.page);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load WhatsApp drafts");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(1);
  }, [load]);

  function setFieldEdit(draftId: string, field: string, value: string) {
    setEdits((prev) => ({ ...prev, [draftId]: { ...prev[draftId], [field]: value } }));
  }

  async function handleApprove(draft: AdminWhatsAppDraft) {
    setActing(draft.id);
    setError("");
    try {
      const draftEdits = edits[draft.id] ?? {};
      const fields = Object.fromEntries(
        EDITABLE_FIELDS.filter((key) => key in draft.extracted_fields || key in draftEdits).map((key) => [
          key,
          key in draftEdits ? draftEdits[key] : formatValue(draft.extracted_fields[key]),
        ]),
      );
      await admin.approveWhatsAppDraft(draft.id, fields);
      setItems((prev) => prev.filter((d) => d.id !== draft.id));
      setTotal((prev) => Math.max(0, prev - 1));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Approve failed");
    } finally {
      setActing(null);
    }
  }

  async function handleReject(draftId: string) {
    setActing(draftId);
    setError("");
    try {
      await admin.rejectWhatsAppDraft(draftId);
      setItems((prev) => prev.filter((d) => d.id !== draftId));
      setTotal((prev) => Math.max(0, prev - 1));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Reject failed");
    } finally {
      setActing(null);
    }
  }

  if (loading && items.length === 0) {
    return <p className="text-sm text-muted">Loading WhatsApp drafts…</p>;
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-4">
      <p className="text-sm text-muted">
        {total} pending {total === 1 ? "suggestion" : "suggestions"} waiting for review.
      </p>
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No WhatsApp suggestions waiting for review
        </p>
      ) : (
        <>
          <div className="space-y-3">
            {items.map((draft) => (
              <div key={draft.id} className="rounded-xl border bg-surface-raised p-4">
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <p className="font-semibold">{draft.business_name}</p>
                  <p className="text-xs text-muted">{new Date(draft.created_at).toLocaleString()}</p>
                </div>
                {draft.degraded && <p className="mt-1 text-xs text-muted">Mock/degraded data.</p>}
                <p className="mt-2 text-xs text-muted">
                  AI suggestions — review and correct before approving, not facts.
                </p>
                <div className="mt-3 space-y-2">
                  {Object.entries(draft.extracted_fields)
                    .filter(([, value]) => value != null && value !== "")
                    .map(([key, value]) =>
                      (EDITABLE_FIELDS as readonly string[]).includes(key) ? (
                        <label key={key} className="block text-sm">
                          <span className="font-medium">{FIELD_LABELS[key] ?? key} (suggestion)</span>
                          <input
                            type="text"
                            defaultValue={formatValue(value)}
                            onChange={(e) => setFieldEdit(draft.id, key, e.target.value)}
                            className="mt-1 w-full rounded-md border bg-surface px-2 py-1 text-sm"
                          />
                        </label>
                      ) : (
                        <p key={key} className="text-sm">
                          <span className="font-medium">{FIELD_LABELS[key] ?? key}</span>
                          <span className="text-muted"> (suggestion, not editable here): </span>
                          <span>{formatValue(value)}</span>
                        </p>
                      ),
                    )}
                </div>
                <div className="mt-3 flex gap-2">
                  <button
                    type="button"
                    disabled={acting === draft.id}
                    onClick={() => handleApprove(draft)}
                    className="rounded-lg bg-green-600 px-3 py-1.5 text-sm text-white hover:bg-green-700 disabled:opacity-50"
                  >
                    Approve
                  </button>
                  <button
                    type="button"
                    disabled={acting === draft.id}
                    onClick={() => handleReject(draft.id)}
                    className="rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/30 disabled:opacity-50"
                  >
                    Reject
                  </button>
                </div>
              </div>
            ))}
          </div>
          {totalPages > 1 && (
            <div className="flex items-center justify-between text-sm">
              <button
                type="button"
                disabled={page <= 1 || loading}
                onClick={() => load(page - 1)}
                className="rounded-md border px-3 py-1.5 disabled:opacity-50"
              >
                Previous
              </button>
              <span className="text-muted">
                Page {page} of {totalPages}
              </span>
              <button
                type="button"
                disabled={page >= totalPages || loading}
                onClick={() => load(page + 1)}
                className="rounded-md border px-3 py-1.5 disabled:opacity-50"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
