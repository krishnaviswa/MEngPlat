"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { businessReports } from "@/lib/api";

/** Public-profile control to report a shop (S-089). Login required. */
export function ReportShopButton({ businessId }: { businessId: string }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [error, setError] = useState("");
  const [ok, setOk] = useState(false);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    setOk(false);
  }, [businessId]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!localStorage.getItem("access_token")) {
      router.push("/login");
      return;
    }
    setError("");
    setSending(true);
    try {
      await businessReports.create(businessId, reason.trim());
      setOk(true);
      setOpen(false);
      setReason("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not send report");
    } finally {
      setSending(false);
    }
  }

  if (ok) {
    return <p className="text-sm text-muted">Report received. Thank you.</p>;
  }

  if (!open) {
    return (
      <button type="button" className="text-sm text-muted underline hover:text-brand-600" onClick={() => setOpen(true)}>
        Report this shop
      </button>
    );
  }

  return (
    <form onSubmit={submit} className="mt-2 space-y-2 rounded-lg border bg-surface-raised p-3">
      <textarea
        required
        minLength={10}
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        className="w-full rounded border border-border px-3 py-2 text-sm"
        rows={3}
        placeholder="What is wrong with this listing?"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex gap-2">
        <button
          type="submit"
          disabled={sending}
          className="rounded bg-brand-600 px-3 py-1 text-sm text-white disabled:opacity-50"
        >
          Submit report
        </button>
        <button type="button" className="text-sm text-muted" onClick={() => setOpen(false)}>
          Cancel
        </button>
      </div>
    </form>
  );
}
