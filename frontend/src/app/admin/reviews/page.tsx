"use client";

import { AllReviewsQueue } from "@/components/admin/AllReviewsQueue";
import { RequireAuth } from "@/components/RequireAuth";

/** Admin — browse reviews across every business and status. */
export default function AdminAllReviewsPage() {
  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <h1 className="text-2xl font-bold">All reviews</h1>
        <p className="text-gray-600">Every review on the platform, regardless of status.</p>
        <div className="mt-6">
          <AllReviewsQueue />
        </div>
      </div>
    </RequireAuth>
  );
}
