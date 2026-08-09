"use client";

import { Dashboard } from "@/components/Dashboard";
import { BusinessForm } from "@/components/BusinessForm";
import { RequireAuth } from "@/components/RequireAuth";

/** Merchant — register a new business (starts pending). */
export default function NewBusinessPage() {
  return (
    <RequireAuth role="merchant">
    <Dashboard
      title="Add business"
      description="Tell customers about your shop or service."
      navItems={[
        { href: "/merchant/dashboard", label: "Overview" },
        { href: "/merchant/businesses/new", label: "Add business" },
        { href: "/settings", label: "Settings" },
      ]}
    >
      <BusinessForm mode="create" onSuccess={() => (window.location.href = "/merchant/dashboard")} />
    </Dashboard>
    </RequireAuth>
  );
}
