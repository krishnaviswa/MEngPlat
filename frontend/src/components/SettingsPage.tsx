"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { auth, clearTokens, performLogout } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { PageHeading } from "@/components/ui/PageHeading";

/** Settings — profile entry point and logout. */
export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);

  const verify = useCallback(() => {
    const token = localStorage.getItem("access_token");
    if (!token) {
      setLoading(false);
      router.replace("/login");
      return;
    }
    auth
      .me()
      .catch(() => {
        clearTokens();
        router.replace("/login");
      })
      .finally(() => setLoading(false));
  }, [router]);

  useEffect(() => {
    verify();
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) verify();
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, [verify]);

  async function logout() {
    await performLogout("/");
  }

  if (loading) return <p className="p-8 text-center">Loading...</p>;

  return (
    <div className="mx-auto max-w-md px-4 py-8">
      <Card>
        <PageHeading size="sm">Settings</PageHeading>
        <p className="mt-2 text-sm text-muted">Manage your account.</p>
        <div className="mt-4 flex flex-wrap gap-3">
          <Button href="/profile" variant="secondary">
            Edit profile
          </Button>
          <Button type="button" variant="danger" onClick={logout}>
            Log out
          </Button>
        </div>
      </Card>
    </div>
  );
}
