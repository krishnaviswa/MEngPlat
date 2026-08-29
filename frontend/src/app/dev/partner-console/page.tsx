"use client";

import { useCallback, useEffect, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { businesses, partnerMock } from "@/lib/api";
import type { Business, PartnerMockCallback, PartnerMockRequestRow } from "@/lib/api";
import { isPartnerMockEnabled } from "@/lib/featureFlags";

/**
 * S-123 — DEV / MOCK billing app.
 *
 * Stands in for Vyapar / Razorpay / a POS: pick a demo shop, enter a fake bill
 * ref, "send a review request". The server signs as the seeded demo partner and
 * calls the real push API — the browser never holds the partner secret. Watch
 * the request list move `pending → submitted` as reviews come in.
 *
 * Gated by `NEXT_PUBLIC_ENABLE_PARTNER_MOCK`; the backend endpoints are
 * independently gated on `debug` + `PARTNERS_PROVIDER=mock`.
 */
export default function PartnerConsolePage() {
  const enabled = isPartnerMockEnabled();
  const [shops, setShops] = useState<Business[]>([]);
  const [slug, setSlug] = useState("");
  const [txn, setTxn] = useState("");
  const [phone, setPhone] = useState("");
  const [collectUrl, setCollectUrl] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [rows, setRows] = useState<PartnerMockRequestRow[]>([]);
  const [callbacks, setCallbacks] = useState<PartnerMockCallback[]>([]);

  const randomTxn = () => `INV-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;

  const refreshRows = useCallback(() => {
    if (!enabled) return;
    partnerMock.requests().then(setRows).catch(() => undefined);
    partnerMock.callbacks().then(setCallbacks).catch(() => undefined);
  }, [enabled]);

  useEffect(() => {
    if (!enabled) return;
    setTxn(randomTxn());
    businesses
      .list({ status_filter: "approved" })
      .then((list) => {
        setShops(list);
        setSlug((s) => s || list[0]?.slug || "");
      })
      .catch(() => undefined);
  }, [enabled]);

  useEffect(() => {
    if (!enabled) return;
    refreshRows();
    const id = setInterval(refreshRows, 4000);
    return () => clearInterval(id);
  }, [enabled, refreshRows]);

  async function dispatch(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setCollectUrl("");
    setMessage("");
    try {
      const res = await partnerMock.dispatch({
        business_slug: slug,
        transaction_ref: txn || undefined,
        customer_phone: phone || undefined,
      });
      setCollectUrl(res.collect_url);
      setMessage(res.message);
      setTxn(randomTxn());
      refreshRows();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Dispatch failed");
    }
  }

  if (!enabled) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16 text-center">
        <p className="text-lg font-semibold">Mock partner console is off</p>
        <p className="mt-1 text-sm text-muted">
          Set <code>NEXT_PUBLIC_ENABLE_PARTNER_MOCK=true</code> (local dev only) to use it.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <div className="mb-4 rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-200">
        DEV / MOCK — this page simulates a billing app (Vyapar, Razorpay…) calling the partner API.
      </div>
      <h1 className="text-2xl font-bold">Mock billing app</h1>
      <p className="mt-1 text-sm text-muted">
        Close a sale → get a single-use review link for the customer&apos;s receipt.
      </p>

      <form onSubmit={dispatch} className="mt-6 space-y-4 rounded-xl border border-border bg-surface-raised p-5 shadow-sm">
        <label className="block text-sm">
          <span className="font-medium text-muted">Shop</span>
          <select
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            className="mt-1 w-full rounded border border-border bg-surface-raised p-2 text-sm text-ink"
          >
            {shops.map((b) => (
              <option key={b.id} value={b.slug}>
                {b.name} ({b.city})
              </option>
            ))}
          </select>
        </label>
        <label className="block text-sm">
          <span className="font-medium text-muted">Invoice / transaction ref</span>
          <input
            value={txn}
            onChange={(e) => setTxn(e.target.value)}
            className="mt-1 w-full rounded border border-border bg-surface-raised p-2 text-sm text-ink"
          />
        </label>
        <label className="block text-sm">
          <span className="font-medium text-muted">Customer phone (optional — stored only as a hash)</span>
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+9198XXXXXX02"
            className="mt-1 w-full rounded border border-border bg-surface-raised p-2 text-sm text-ink"
          />
        </label>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button type="submit" className="rounded bg-brand-600 px-4 py-2 text-sm font-medium text-white">
          Send review request
        </button>
      </form>

      {collectUrl && (
        <div className="mt-4 rounded-xl border border-border bg-surface-raised p-5 text-center shadow-sm">
          <p className="text-sm font-medium text-muted">Message the partner would send the customer:</p>
          <p className="mt-2 rounded bg-surface p-3 text-left text-sm text-ink">{message}</p>
          <div className="mt-3 flex justify-center">
            <QRCodeSVG value={collectUrl} size={128} />
          </div>
          <a
            href={collectUrl}
            target="_blank"
            rel="noreferrer"
            className="mt-3 block break-all text-sm font-medium text-brand-700 hover:underline"
          >
            {collectUrl}
          </a>
        </div>
      )}

      <h2 className="mt-8 text-lg font-semibold">Review requests</h2>
      <p className="text-sm text-muted">Auto-refreshes — watch a row flip to “submitted” after a review is left.</p>
      <div className="mt-3 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="text-xs uppercase text-muted">
            <tr>
              <th className="py-2 pr-3">Shop</th>
              <th className="py-2 pr-3">Txn ref</th>
              <th className="py-2 pr-3">Status</th>
              <th className="py-2">Review</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr>
                <td colSpan={4} className="py-3 text-muted">
                  No requests yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <tr key={r.token} className="border-t border-border">
                <td className="py-2 pr-3">{r.business_slug}</td>
                <td className="py-2 pr-3 font-mono text-xs">{r.partner_txn_ref}</td>
                <td className="py-2 pr-3">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs ${
                      r.status === "submitted"
                        ? "bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300"
                        : r.status === "expired"
                          ? "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"
                          : "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300"
                    }`}
                  >
                    {r.status}
                  </span>
                </td>
                <td className="py-2 text-xs">
                  {r.review_id ? (
                    <a
                      href={`/businesses/${r.business_slug}`}
                      target="_blank"
                      rel="noreferrer"
                      className="text-brand-700 hover:underline"
                    >
                      ✓ view on listing →
                    </a>
                  ) : (
                    <span className="text-muted">—</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="mt-8 text-lg font-semibold">Callbacks received from MerchantHub</h2>
      <p className="text-sm text-muted">
        The signed <code>review.captured</code> events MerchantHub POSTs back after moderation clears.
      </p>
      <ul className="mt-3 space-y-2">
        {callbacks.length === 0 && <li className="text-sm text-muted">None yet.</li>}
        {callbacks.map((c, i) => (
          <li key={`${c.received_at}-${i}`} className="rounded-lg border border-border bg-surface-raised p-3 text-xs">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-green-100 px-2 py-0.5 font-medium text-green-800 dark:bg-green-900/40 dark:text-green-300">
                {String((c.event as { event?: string }).event ?? "callback")}
              </span>
              <span className="text-muted">{new Date(c.received_at).toLocaleTimeString()}</span>
              <span className="text-muted">
                status: {String((c.event as { status?: string }).status ?? "—")} · rating:{" "}
                {String((c.event as { rating?: number }).rating ?? "—")}
              </span>
            </div>
            <p className="mt-1 truncate font-mono text-muted">sig {c.signature ?? "—"}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
