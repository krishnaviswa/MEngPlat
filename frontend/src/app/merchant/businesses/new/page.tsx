"use client";

import { useState } from "react";
import { Dashboard } from "@/components/Dashboard";
import { BusinessForm, type BusinessFormValues } from "@/components/BusinessForm";
import { OnboardingGuidancePanel } from "@/components/OnboardingGuidancePanel";
import { RequireAuth } from "@/components/RequireAuth";

/** Merchant — register a new business (starts pending). */
export default function NewBusinessPage() {
  const [formSnapshot, setFormSnapshot] = useState<BusinessFormValues | null>(null);

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
      sidePanel={<OnboardingGuidancePanel formState={formSnapshot} />}
    >
      <BusinessForm
        mode="create"
        onSuccess={() => (window.location.href = "/merchant/dashboard")}
        onFormStateChange={setFormSnapshot}
      />
    </Dashboard>
    </RequireAuth>
  );
}
