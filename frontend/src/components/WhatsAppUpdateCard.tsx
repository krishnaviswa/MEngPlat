"use client";

import { useEffect, useRef, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { dashboard, type WhatsAppLink } from "@/lib/api";

/** Merchant QR that opens a WhatsApp chat bound to this listing (S-050). */
export function WhatsAppUpdateCard({
  businessId,
  businessName,
}: {
  businessId: string;
  businessName?: string;
}) {
  const [link, setLink] = useState<WhatsAppLink | null>(null);
  const [error, setError] = useState<string | null>(null);
  const qrWrapperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;
    dashboard
      .createWhatsAppLink(businessId)
      .then((payload) => {
        if (!cancelled) setLink(payload);
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message || "Could not create WhatsApp link");
      });
    return () => {
      cancelled = true;
    };
  }, [businessId]);

  function handlePrint() {
    const svg = qrWrapperRef.current?.querySelector("svg");
    if (!svg || !link?.wa_url) return;
    const printWindow = window.open("", "_blank", "width=400,height=500");
    if (!printWindow) return;
    printWindow.document.write(`
      <html>
        <head>
          <title>WhatsApp shop update — ${businessName ?? "MerchantHub"}</title>
          <style>
            body { font-family: sans-serif; text-align: center; padding: 40px 20px; }
            h1 { font-size: 20px; margin-bottom: 8px; }
            p { font-size: 14px; color: #555; margin-top: 16px; word-break: break-all; }
          </style>
        </head>
        <body>
          <h1>${businessName ? `Scan to update ${businessName} on WhatsApp` : "Scan to send shop details on WhatsApp"}</h1>
          ${svg.outerHTML}
          <p>${link.wa_url}</p>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
    printWindow.close();
  }

  if (error) {
    return (
      <section className="rounded-xl border border-border bg-surface-raised p-4">
        <h3 className="font-semibold">Update shop via WhatsApp</h3>
        <p className="mt-1 text-sm text-muted">{error}</p>
      </section>
    );
  }

  if (!link) {
    return (
      <section className="rounded-xl border border-border bg-surface-raised p-4">
        <h3 className="font-semibold">Update shop via WhatsApp</h3>
        <p className="mt-1 text-sm text-muted">Preparing your WhatsApp link…</p>
      </section>
    );
  }

  if (!link.available || !link.wa_url) {
    return (
      <section className="rounded-xl border border-border bg-surface-raised p-4">
        <h3 className="font-semibold">Update shop via WhatsApp</h3>
        <p className="mt-1 text-sm text-muted">
          WhatsApp updates aren&apos;t set up for this platform yet — this needs a one-time
          configuration change from the MerchantHub team, not an action you or an admin can take
          in-app.
        </p>
      </section>
    );
  }

  return (
    <section className="rounded-xl border border-border bg-surface-raised p-4">
      <h3 className="font-semibold">Update shop via WhatsApp</h3>
      <p className="mt-1 text-sm text-muted">
        Scan to send hours, address, description, or photos. Text suggestions wait for your approval before going live.
      </p>
      <div className="mt-3" ref={qrWrapperRef}>
        <QRCodeSVG value={link.wa_url} size={128} />
      </div>
      <p className="mt-2 break-all text-xs text-muted">{link.wa_url}</p>
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
