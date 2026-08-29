"use client";

import { useEffect, useState } from "react";
import { Input } from "@/components/ui/Input";
import { businessReports, support, type BusinessReport, type SupportTicket } from "@/lib/api";

/** Support ticket form + optional "my tickets" list (S-087 / S-088). */
export function SupportTicketForm() {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [issue, setIssue] = useState("");
  const [businessId, setBusinessId] = useState("");
  const [error, setError] = useState("");
  const [ok, setOk] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [mine, setMine] = useState<SupportTicket[] | null>(null);
  const [reports, setReports] = useState<BusinessReport[] | null>(null);

  useEffect(() => {
    if (typeof window === "undefined" || !localStorage.getItem("access_token")) return;
    support
      .myTickets()
      .then(setMine)
      .catch(() => setMine([]));
    businessReports
      .mine()
      .then(setReports)
      .catch(() => setReports([]));
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setOk("");
    setSubmitting(true);
    try {
      const ticket = await support.createTicket({
        name: name.trim(),
        phone: phone.trim(),
        issue: issue.trim(),
        ...(businessId.trim() ? { business_id: businessId.trim() } : {}),
      });
      setOk(`Ticket submitted (${ticket.status}). Reference ${ticket.id.slice(0, 8)}…`);
      setIssue("");
      if (mine) setMine([ticket, ...mine]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not submit");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-8">
      <form onSubmit={handleSubmit} className="space-y-3 rounded-xl border border-border bg-surface-raised p-4">
        <label className="block text-sm font-medium">
          Name
          <Input className="mt-1" required value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label className="block text-sm font-medium">
          Phone
          <Input className="mt-1" required value={phone} onChange={(e) => setPhone(e.target.value)} />
        </label>
        <label className="block text-sm font-medium">
          Issue
          <textarea
            required
            minLength={10}
            value={issue}
            onChange={(e) => setIssue(e.target.value)}
            className="mt-1 w-full rounded border border-border bg-surface-raised px-3 py-2 text-sm"
            rows={5}
          />
        </label>
        <label className="block text-sm font-medium">
          Related business ID (optional)
          <Input
            className="mt-1"
            value={businessId}
            onChange={(e) => setBusinessId(e.target.value)}
            placeholder="UUID from the shop URL if you have it"
          />
        </label>
        {error && <p className="text-sm text-red-600">{error}</p>}
        {ok && <p className="text-sm text-green-700 dark:text-green-400">{ok}</p>}
        <button
          type="submit"
          disabled={submitting}
          className="rounded bg-brand-600 px-4 py-2 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {submitting ? "Sending…" : "Submit"}
        </button>
      </form>

      {reports && (
        <section>
          <h2 className="text-lg font-semibold">Your shop reports</h2>
          {reports.length === 0 ? (
            <p className="mt-2 text-sm text-muted">No shop reports yet.</p>
          ) : (
            <ul className="mt-3 space-y-3">
              {reports.map((r) => (
                <li key={r.id} className="rounded-xl border border-border bg-surface-raised p-4 text-sm">
                  <p className="font-medium">
                    {r.business_name || r.business_id} · {r.status.replace("_", " ")}
                    {r.is_repeat ? " · repeat shop" : ""}
                  </p>
                  <p className="mt-1 text-muted">{r.reason}</p>
                  {r.messages.map((m) => (
                    <p key={m.id} className="mt-2 rounded bg-surface p-2">
                      {m.body}
                    </p>
                  ))}
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
      {mine && (
        <section>
          <h2 className="text-lg font-semibold">Your tickets</h2>
          {mine.length === 0 ? (
            <p className="mt-2 text-sm text-muted">No tickets yet.</p>
          ) : (
            <ul className="mt-3 space-y-3">
              {mine.map((t) => (
                <li key={t.id} className="rounded-xl border border-border bg-surface-raised p-4 text-sm">
                  <p className="font-medium">{t.status.replace("_", " ")}</p>
                  <p className="mt-1 text-muted">{t.issue}</p>
                  {t.admin_response && (
                    <p className="mt-2 rounded bg-surface p-2">Admin: {t.admin_response}</p>
                  )}
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
    </div>
  );
}
