"use client";

import { AdminBackLink } from "@/components/AdminBackLink";
import { AllReviewsQueue } from "@/components/admin/AllReviewsQueue";
import { RequireAuth } from "@/components/RequireAuth";
import { PageHeading } from "@/components/ui/PageHeading";

/** Admin — browse reviews across every business and status. */
export default function AdminAllReviewsPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <AdminBackLink />
        <PageHeading>All reviews</PageHeading>
        <p className="text-muted">Every review on the platform, regardless of status.</p>
        <div className="mt-6">
          <AllReviewsQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
