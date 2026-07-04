"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { auth } from "@/lib/api";

/** Settings — account settings and logout. */
export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    auth.me().catch(() => router.push("/login")).finally(() => setLoading(false));
  }, [router]);

  function logout() {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    router.push("/");
  }

  if (loading) return <p className="p-8 text-center">Loading...</p>;

  return (
    <div className="mx-auto max-w-md rounded-xl border bg-white p-6 shadow-sm">
      <h1 className="text-xl font-bold">Settings</h1>
      <button onClick={logout} className="mt-4 rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700">
        Log out
      </button>
    </div>
  );
}
