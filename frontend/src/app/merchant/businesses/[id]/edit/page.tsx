"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { BusinessForm } from "@/components/BusinessForm";
import { Dashboard } from "@/components/Dashboard";
import { RequireAuth } from "@/components/RequireAuth";
import { businesses } from "@/lib/api";
import type { Business } from "@/lib/api";

/** Merchant — edit an owned business by id. */
export default function EditBusinessPage() {
  const params = useParams<{ id: string }>();
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    businesses
      .mine()
      .then((list) => {
        const match = list.find((b) => b.id === params.id);
        if (!match) {
          setError("Business not found or you do not have access.");
          return;
        }
        setBusiness(match);
      })
      .catch(() => setError("Could not load your businesses."))
      .finally(() => setLoading(false));
  }, [params.id]);

  if (loading) {
    return (
      <RequireAuth role="merchant">
        <p className="p-8 text-center">Loading...</p>
      </RequireAuth>
    );
  }
  if (error || !business) {
    return (
      <RequireAuth role="merchant">
      <Dashboard
        title="Edit business"
        navItems={[
          { href: "/merchant/dashboard", label: "Overview" },
          { href: "/settings", label: "Settings" },
        ]}
      >
        <p className="rounded-xl border border-border bg-surface-raised p-6 text-center text-red-700 dark:text-red-400">{error || "Not found"}</p>
      </Dashboard>
      </RequireAuth>
    );
  }

  return (
    <RequireAuth role="merchant">
    <Dashboard
      title="Edit business"
      description={business.name}
      navItems={[
        { href: "/merchant/dashboard", label: "Overview" },
        { href: `/merchant/businesses/${business.id}/edit`, label: "Edit business" },
        { href: `/businesses/${business.slug}`, label: "Public profile" },
        { href: "/settings", label: "Settings" },
      ]}
    >
      <BusinessForm
        mode="edit"
        business={business}
        onSuccess={() => (window.location.href = "/merchant/dashboard")}
      />
    </Dashboard>
    </RequireAuth>
  );
}
