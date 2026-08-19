"use client";

import { AdminBackLink } from "@/components/AdminBackLink";
import { AdminBusinessReportsQueue } from "@/components/admin/AdminBusinessReportsQueue";
import { RequireAuth } from "@/components/RequireAuth";

/** Admin — shop-level reports (S-089). Distinct from review reports. */
export default function AdminBusinessReportsPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <h1 className="text-2xl font-bold">Shop reports</h1>
        <p className="text-muted">Reports against a listing, not a review. Repeat = 3 or more reports on the same shop.</p>
        <div className="mt-6">
          <AdminBusinessReportsQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
