"use client";

import { useCallback, useEffect, useState } from "react";
import { payments, type PlacementResponse } from "@/lib/api";

interface FeaturedBoostPanelProps {
  businessId: string;
  listingStatus: string;
}

declare global {
  interface Window {
    Razorpay?: new (options: Record<string, unknown>) => { open: () => void };
  }
}

/** Buy or view a 7-day ₹499 featured search boost for an owned listing. */
export function FeaturedBoostPanel({ businessId, listingStatus }: FeaturedBoostPanelProps) {
  const [placement, setPlacement] = useState<PlacementResponse | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
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

  async function startCheckout() {
    setError("");
    setBusy(true);
    try {
      const result = await payments.checkoutFeatured(businessId);
      if (result.provider === "razorpay") {
        await openRazorpay(result.checkout);
        await load();
      } else {
        setPendingOrder(result.provider_order_id);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Checkout failed");
    } finally {
      setBusy(false);
    }
  }

  const approved = listingStatus === "approved";
  const activeUntil = placement?.active && placement.placement?.ends_at
    ? new Date(placement.placement.ends_at).toLocaleString()
    : null;

  return (
    <section className="rounded-xl border bg-white p-4">
      <h3 className="font-semibold">Featured listing boost</h3>
      <p className="mt-1 text-sm text-gray-600">
        ₹{placement?.sku.listed_price_inr ?? 499} for {placement?.sku.duration_days ?? 7} days of paid search
        placement. This is not an AI quality score.
      </p>
      {activeUntil && (
        <p className="mt-2 text-sm text-green-700">
          Active until <strong>{activeUntil}</strong>
        </p>
      )}
      {!approved && (
        <p className="mt-2 text-sm text-amber-800">Boost is available only after the listing is approved.</p>
      )}
      {approved && !placement?.active && (
        <button
          type="button"
          onClick={startCheckout}
          disabled={busy}
          className="mt-3 rounded bg-brand-600 px-3 py-1.5 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {busy ? "Starting…" : "Boost this listing — ₹499 / 7 days"}
        </button>
      )}
      {pendingOrder && (
        <p className="mt-2 text-sm text-gray-600">
          Demo order <code className="text-xs">{pendingOrder}</code> created. An admin completes it with mock
          complete (DEBUG). Cards never go to this app.
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
