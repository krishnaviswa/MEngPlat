"use client";

import { AdminBackLink } from "@/components/AdminBackLink";
import { AdminWhatsAppDraftsQueue } from "@/components/admin/AdminWhatsAppDraftsQueue";
import { RequireAuth } from "@/components/RequireAuth";

/** Admin — review queue for AI-extracted WhatsApp profile suggestions (S-053). */
export default function AdminWhatsAppDraftsPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <h1 className="text-2xl font-bold">WhatsApp updates</h1>
        <p className="text-muted">
          AI-extracted profile suggestions submitted by merchants over WhatsApp. Review, correct if needed, and
          approve or reject before anything reaches a live listing.
        </p>
        <div className="mt-6">
          <AdminWhatsAppDraftsQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
