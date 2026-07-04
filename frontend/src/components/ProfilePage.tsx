"use client";

import { useEffect, useState } from "react";
import type { User } from "@/lib/api";
import { auth } from "@/lib/api";

/** Profile — view/edit user profile. Hooks: useState, useEffect for auth fetch. */
export default function ProfilePage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    auth.me()
      .then(setUser)
      .catch(() => setUser(null))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p className="p-8 text-center">Loading...</p>;
  if (!user) return <p className="p-8 text-center">Please <a href="/login" className="text-brand-600">login</a>.</p>;

  return (
    <div className="mx-auto max-w-md rounded-xl border bg-white p-6 shadow-sm">
      <h1 className="text-xl font-bold">Profile</h1>
      <dl className="mt-4 space-y-2 text-sm">
        <div><dt className="text-gray-500">Name</dt><dd className="font-medium">{user.full_name}</dd></div>
        <div><dt className="text-gray-500">Email</dt><dd>{user.email}</dd></div>
        <div><dt className="text-gray-500">Role</dt><dd className="capitalize">{user.role}</dd></div>
      </dl>
    </div>
  );
}
