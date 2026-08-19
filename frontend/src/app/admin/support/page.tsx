"use client";

import { AdminBackLink } from "@/components/AdminBackLink";
import { AdminSupportQueue } from "@/components/admin/AdminSupportQueue";
import { RequireAuth } from "@/components/RequireAuth";

/** Admin — support tickets (S-088). */
export default function AdminSupportPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <h1 className="text-2xl font-bold">Support tickets</h1>
        <p className="text-muted">Customer and merchant queries. Review reports stay on the reviews queue.</p>
        <div className="mt-6">
          <AdminSupportQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
