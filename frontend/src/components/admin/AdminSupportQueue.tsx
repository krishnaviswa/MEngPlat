"use client";

import { useCallback, useEffect, useState } from "react";
import { support, type SupportTicket, type TicketStatus } from "@/lib/api";

/** Admin queue — support tickets (S-088). */
export function AdminSupportQueue() {
  const [items, setItems] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>({});

  const load = useCallback(async () => {
    setError("");
    try {
      setItems(await support.adminTickets());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load tickets");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function save(ticket: SupportTicket, status: TicketStatus) {
    setActing(ticket.id);
    try {
      const updated = await support.updateTicket(ticket.id, {
        status,
        admin_response: drafts[ticket.id] ?? ticket.admin_response ?? "",
      });
      setItems((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setActing(null);
    }
  }

  if (loading) return <p className="text-sm text-muted">Loading tickets…</p>;

  return (
    <div className="space-y-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No support tickets
        </p>
      ) : (
        items.map((t) => (
          <div key={t.id} className="rounded-xl border bg-surface-raised p-4">
            <p className="font-semibold">
              {t.name} · {t.phone} · {t.status}
            </p>
            <p className="mt-1 text-sm text-muted">{t.issue}</p>
            <textarea
              className="mt-3 w-full rounded border border-border px-3 py-2 text-sm"
              rows={2}
              placeholder="Response to the customer"
              value={drafts[t.id] ?? t.admin_response ?? ""}
              onChange={(e) => setDrafts((d) => ({ ...d, [t.id]: e.target.value }))}
            />
            <div className="mt-2 flex flex-wrap gap-2">
              {(["open", "in_progress", "resolved"] as TicketStatus[]).map((s) => (
                <button
                  key={s}
                  type="button"
                  disabled={acting === t.id}
                  onClick={() => save(t, s)}
                  className="rounded border px-3 py-1 text-sm hover:bg-surface disabled:opacity-50"
                >
                  Mark {s.replace("_", " ")}
                </button>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  );
}
