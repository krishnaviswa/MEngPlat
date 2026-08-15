"use client";

import { useCallback, useEffect, useState } from "react";
import { payments, type FeaturedSku, type PlacementResponse } from "@/lib/api";

interface FeaturedBoostPanelProps {
  businessId: string;
  listingStatus: string;
}

declare global {
  interface Window {
    Razorpay?: new (options: Record<string, unknown>) => { open: () => void };
  }
}

const FALLBACK_SKUS: FeaturedSku[] = [
  { code: "featured_7d", duration_days: 7, listed_price_inr: 299 },
  { code: "featured_15d", duration_days: 15, listed_price_inr: 499 },
  { code: "featured_30d", duration_days: 30, listed_price_inr: 899 },
];

/** Buy or view a featured search boost. Three SKUs; mock waits for admin; capture does not auto-feature. */
export function FeaturedBoostPanel({ businessId, listingStatus }: FeaturedBoostPanelProps) {
  const [placement, setPlacement] = useState<PlacementResponse | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [pendingOrder, setPendingOrder] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setPlacement(await payments.placement(businessId));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load placement");
    }
  }, [businessId]);

  useEffect(() => {
    load();
  }, [load]);

  async function startCheckout(skuCode: string) {
    setError("");
    setBusy(skuCode);
    try {
      const result = await payments.checkoutFeatured(businessId, skuCode);
      if (result.provider === "razorpay") {
        if (!result.checkout.key_id) {
          throw new Error("Payments are not configured. Ask an admin to set Razorpay keys, or use mock mode.");
        }
        await openRazorpay(result.checkout);
        await load();
      } else {
        setPendingOrder(result.provider_order_id);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Checkout failed");
    } finally {
      setBusy(null);
    }
  }

  const approved = listingStatus === "approved";
  const skus = placement?.skus?.length ? placement.skus : FALLBACK_SKUS;
  const activeUntil =
    placement?.active && placement.placement?.ends_at
      ? new Date(placement.placement.ends_at).toLocaleString()
      : null;
  const awaiting = Boolean(placement?.awaiting_approval);

  return (
    <section className="rounded-xl border bg-surface-raised p-4">
      <h3 className="font-semibold">Featured listing boost</h3>
      <p className="mt-1 text-sm text-muted">
        Paid search placement for a fixed period. This is not an AI quality score.
      </p>
      {activeUntil && (
        <p className="mt-2 text-sm text-green-700 dark:text-green-400">
          Active until <strong>{activeUntil}</strong>
        </p>
      )}
      {awaiting && (
        <p className="mt-2 text-sm text-amber-800 dark:text-amber-400">
          Payment received. Waiting for an admin to approve this boost before it appears in search.
        </p>
      )}
      {!approved && (
        <p className="mt-2 text-sm text-amber-800 dark:text-amber-400">Boost is available only after the listing is approved.</p>
      )}
      {approved && !placement?.active && !awaiting && (
        <div className="mt-3 grid gap-2 sm:grid-cols-3">
          {skus.map((sku) => (
            <button
              key={sku.code}
              type="button"
              onClick={() => startCheckout(sku.code)}
              disabled={busy !== null}
              className="rounded border border-brand-200 bg-brand-50 px-3 py-2 text-left text-sm hover:border-brand-400 disabled:opacity-50"
            >
              <span className="block font-semibold text-brand-800">
                ₹{sku.listed_price_inr} / {sku.duration_days === 30 ? "1 month" : `${sku.duration_days} days`}
              </span>
              <span className="text-xs text-muted">
                {busy === sku.code ? "Starting…" : "Boost this listing"}
              </span>
            </button>
          ))}
        </div>
      )}
      {pendingOrder && (
        <p className="mt-2 text-sm text-muted">
          Demo order <code className="text-xs">{pendingOrder}</code> created. An admin records the mock capture,
          then approves the boost. Cards never go to this app.
        </p>
      )}
      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
    </section>
  );
}

async function openRazorpay(checkout: {
  key_id: string;
  order_id: string;
  amount: number;
  currency: string;
  name: string;
  description: string;
  prefill?: Record<string, string>;
}): Promise<void> {
  await loadCheckoutScript();
  await new Promise<void>((resolve, reject) => {
    if (!window.Razorpay) {
      reject(new Error("Checkout failed to load"));
      return;
    }
    const rzp = new window.Razorpay({
      key: checkout.key_id,
      amount: checkout.amount,
      currency: checkout.currency,
      name: checkout.name,
      description: checkout.description,
      order_id: checkout.order_id,
      prefill: checkout.prefill,
      handler: () => resolve(),
      modal: { ondismiss: () => resolve() },
    });
    rzp.open();
  });
}

function loadCheckoutScript(): Promise<void> {
  if (window.Razorpay) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Could not load Razorpay Checkout"));
    document.body.appendChild(script);
  });
}
