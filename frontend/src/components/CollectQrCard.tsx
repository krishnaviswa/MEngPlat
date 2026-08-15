"use client";

import { QRCodeSVG } from "qrcode.react";

/** Merchant QR for the public collect-review URL. */
export function CollectQrCard({ businessId }: { businessId: string }) {
  const origin = typeof window === "undefined" ? "" : window.location.origin;
  const url = `${origin}/collect/${businessId}`;
  if (!origin) return null;
  return (
    <section className="rounded-xl border bg-white p-4">
      <h3 className="font-semibold">Review collection QR</h3>
      <p className="mt-1 text-sm text-gray-600">Customers scan this to leave any star rating — no low-score intercept.</p>
      <div className="mt-3">
        <QRCodeSVG value={url} size={128} />
      </div>
      <p className="mt-2 break-all text-xs text-gray-500">{url}</p>
    </section>
  );
}
