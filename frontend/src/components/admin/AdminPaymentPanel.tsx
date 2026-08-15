"use client";

import { useCallback, useEffect, useState } from "react";
import { payments, type AdminPaymentRow } from "@/lib/api";

function rupees(paise: number | null): string {
  if (paise == null) return "—";
  return `₹${(paise / 100).toFixed(2)}`;
}

/** Admin — featured payment history, mock complete, approve/reject, refund. */
export function AdminPaymentPanel() {
  const [items, setItems] = useState<AdminPaymentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError("");
    try {
      setItems(await payments.listAdmin({ page: 1, page_size: 50 }));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load payments");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function run(id: string, fn: () => Promise<unknown>) {
    setActing(id);
    setError("");
    try {
      await fn();
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Action failed");
    } finally {
      setActing(null);
    }
  }

  if (loading) return <p className="text-sm text-muted">Loading payments…</p>;

  return (
    <div className="space-y-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          No featured payments yet
        </p>
      ) : (
        items.map((p) => (
          <div key={p.id} className="rounded-xl border bg-surface-raised p-4 text-sm">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div>
                <p className="font-semibold">{p.business_name || "Listing"}</p>
                <p className="text-muted">
                  {p.merchant_name} · {p.merchant_email || "no email"} · {p.merchant_payment_count} payment
                  {p.merchant_payment_count === 1 ? "" : "s"}
                </p>
                <p className="mt-1 text-muted">
                  {p.sku_code} · {p.duration_days} days · {rupees(p.amount_paise)} · {p.status}
                  {p.awaiting_approval ? " · awaiting boost approval" : ""}
                </p>
                <p className="text-xs text-muted">
                  Order <code>{p.provider_order_id}</code>
                  {p.platform_fee_paise != null && (
                    <>
                      {" "}
                      · platform {rupees(p.platform_fee_paise)} · gateway {rupees(p.gateway_fee_paise)}
                    </>
                  )}
                </p>
              </div>
              <a href={`/admin/businesses/${p.business_id}`} className="text-brand-700 underline">
                Open listing
              </a>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {p.status === "created" && p.provider === "mock" && (
                <button
                  type="button"
                  className="rounded border px-3 py-1.5"
                  disabled={acting === p.id}
                  onClick={() => run(p.id, () => payments.mockComplete(p.provider_order_id, "paid"))}
                >
                  Complete mock (DEBUG)
                </button>
              )}
              {p.awaiting_approval && (
                <>
                  <button
                    type="button"
                    className="rounded bg-brand-600 px-3 py-1.5 text-white"
                    disabled={acting === p.id}
                    onClick={() => run(p.id, () => payments.approvePayment(p.id))}
                  >
                    Approve boost
                  </button>
                  <button
                    type="button"
                    className="rounded border px-3 py-1.5"
                    disabled={acting === p.id}
                    onClick={() => run(p.id, () => payments.rejectPayment(p.id))}
                  >
                    Reject
                  </button>
                </>
              )}
              {p.status === "paid" && (
                <button
                  type="button"
                  className="rounded border px-3 py-1.5"
                  disabled={acting === p.id}
                  onClick={() => run(p.id, () => payments.refundPayment(p.id))}
                >
                  Refund
                </button>
              )}
            </div>
          </div>
        ))
      )}
    </div>
  );
}
