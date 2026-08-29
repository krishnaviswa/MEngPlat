"use client";

import { useRef } from "react";
import { QRCodeSVG } from "qrcode.react";

/** Merchant QR for the public collect-review URL, with a print button for a shop-counter sign. */
export function CollectQrCard({ businessId, businessName }: { businessId: string; businessName?: string }) {
  const origin = typeof window === "undefined" ? "" : window.location.origin;
  const url = `${origin}/collect/${businessId}`;
  const qrWrapperRef = useRef<HTMLDivElement>(null);

  function handlePrint() {
    const svg = qrWrapperRef.current?.querySelector("svg");
    if (!svg) return;
    const printWindow = window.open("", "_blank", "width=400,height=500");
    if (!printWindow) return;
    printWindow.document.write(`
      <html>
        <head>
          <title>Review QR — ${businessName ?? "MerchantHub"}</title>
          <style>
            body { font-family: sans-serif; text-align: center; padding: 40px 20px; }
            h1 { font-size: 20px; margin-bottom: 8px; }
            p { font-size: 14px; color: #555; margin-top: 16px; word-break: break-all; }
          </style>
        </head>
        <body>
          <h1>${businessName ? `Scan to review ${businessName}` : "Scan to leave a review"}</h1>
          ${svg.outerHTML}
          <p>${url}</p>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
    printWindow.close();
  }

  if (!origin) return null;
  return (
    <section className="rounded-xl border border-border bg-surface-raised p-4">
      <h3 className="font-semibold">Review collection QR</h3>
      <p className="mt-1 text-sm text-muted">Customers scan this to leave any star rating — no low-score intercept.</p>
      <div className="mt-3" ref={qrWrapperRef}>
        <QRCodeSVG value={url} size={128} />
      </div>
      <p className="mt-2 break-all text-xs text-muted">{url}</p>
      <button
        type="button"
        onClick={handlePrint}
        className="mt-3 rounded-md border border-border px-3 py-1.5 text-sm font-medium hover:bg-surface"
      >
        Print for shop
      </button>
    </section>
  );
}
