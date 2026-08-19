"use client";

import { useCallback, useEffect, useState } from "react";
import { AdminBackLink } from "@/components/AdminBackLink";
import { Badge } from "@/components/ui/Badge";
import { RequireAuth } from "@/components/RequireAuth";
import { businessReports, type BusinessReport, type TicketStatus } from "@/lib/api";

/** Admin queue — shop-level reports (S-089). Distinct from review reports. */
export function AdminBusinessReportsQueue() {
  const [items, setItems] = useState<BusinessReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [reply, setReply] = useState<Record<string, string>>({});
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError("");
    try {
      setItems(await businessReports.adminList());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load reports");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function send(id: string) {
    const body = (reply[id] || "").trim();
    if (!body) return;
    setActing(id);
    try {
      await businessReports.adminMessage(id, body);
      setReply((r) => ({ ...r, [id]: "" }));
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Message failed");
    } finally {
      setActing(null);
    }
  }

  async function setStatus(id: string, status: TicketStatus) {
    setActing(id);
    try {
      const updated = await businessReports.adminUpdate(id, status);
      setItems((prev) => prev.map((r) => (r.id === updated.id ? updated : r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setActing(null);
    }
  }

  if (loading) return <p className="text-sm text-muted">Loading shop reports…</p>;

  return (
    <div className="space-y-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No shop reports
        </p>
      ) : (
        items.map((r) => (
          <div key={r.id} className="rounded-xl border bg-surface-raised p-4">
            <div className="flex flex-wrap items-center gap-2">
              <p className="font-semibold">{r.business_name || r.business_id}</p>
              {r.is_repeat && <Badge tone="negative">Repeat ({r.report_count})</Badge>}
              <span className="text-sm text-muted">{r.status}</span>
            </div>
            <p className="mt-2 text-sm">{r.reason}</p>
            <ul className="mt-3 space-y-1 text-sm text-muted">
              {r.messages.map((m) => (
                <li key={m.id}>
                  {new Date(m.created_at).toLocaleString()}: {m.body}
                </li>
              ))}
            </ul>
            <textarea
              className="mt-3 w-full rounded border border-border px-3 py-2 text-sm"
              rows={2}
              value={reply[r.id] ?? ""}
              onChange={(e) => setReply((d) => ({ ...d, [r.id]: e.target.value }))}
              placeholder="Message the reporter"
            />
            <div className="mt-2 flex flex-wrap gap-2">
              <button
                type="button"
                disabled={acting === r.id}
                onClick={() => send(r.id)}
                className="rounded bg-brand-600 px-3 py-1 text-sm text-white disabled:opacity-50"
              >
                Send
              </button>
              {(["open", "in_progress", "resolved"] as TicketStatus[]).map((s) => (
                <button
                  key={s}
                  type="button"
                  disabled={acting === r.id}
                  onClick={() => setStatus(r.id, s)}
                  className="rounded border px-3 py-1 text-sm disabled:opacity-50"
                >
                  {s.replace("_", " ")}
                </button>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  );
}

export default function AdminBusinessReportsPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <h1 className="text-2xl font-bold">Shop reports</h1>
        <p className="text-muted">Reports against a listing, not a review. Repeat = 3 or more reports on the same shop.</p>
        <div className="mt-6">
          <AdminBusinessReportsQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
