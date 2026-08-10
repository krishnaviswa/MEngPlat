"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { auth } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";

/** Settings — profile entry point and logout. */
export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    auth.me().catch(() => router.push("/login")).finally(() => setLoading(false));
  }, [router]);

  async function logout() {
    try {
      await auth.logout();
    } catch {
      // best-effort server-side revoke; local logout proceeds regardless
    }
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    router.push("/");
  }

  if (loading) return <p className="p-8 text-center">Loading...</p>;

  return (
    <div className="mx-auto max-w-md px-4 py-8">
      <Card>
        <h1 className="text-xl font-bold">Settings</h1>
        <p className="mt-2 text-sm text-gray-600">Manage your account.</p>
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
