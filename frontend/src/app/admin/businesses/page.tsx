"use client";

import { AdminBackLink } from "@/components/AdminBackLink";
import { AllBusinessesQueue } from "@/components/admin/AllBusinessesQueue";
import { RequireAuth } from "@/components/RequireAuth";
import { PageHeading } from "@/components/ui/PageHeading";

/** Admin — browse businesses of every status (approved, pending, rejected, suspended). */
export default function AdminAllBusinessesPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <PageHeading>All businesses</PageHeading>
        <p className="text-muted">Every business on the platform, regardless of status.</p>
        <div className="mt-6">
          <AllBusinessesQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
