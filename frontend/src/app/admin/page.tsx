"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api";

/** Admin moderation panel — CSR with protected API calls. */
export default function AdminPage() {
  const [stats, setStats] = useState<Record<string, number> | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    apiFetch<Record<string, number>>("/api/v1/dashboard/admin/platform")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  if (error) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-16 text-center">
        <p className="text-red-600">{error}</p>
        <p className="mt-2 text-sm text-gray-500">Login as admin@merchanthub.ai / admin12345</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      <h1 className="text-2xl font-bold">Admin Panel</h1>
      <p className="text-gray-600">Platform moderation and analytics</p>
      {stats && (
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Object.entries(stats).map(([key, value]) => (
            <div key={key} className="rounded-xl border bg-white p-4">
              <p className="text-sm capitalize text-gray-500">{key.replace(/_/g, " ")}</p>
              <p className="text-2xl font-bold">{value}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
