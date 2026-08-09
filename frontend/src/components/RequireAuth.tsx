"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { auth, type User } from "@/lib/api";

interface RequireAuthProps {
  /** When set, user must have this role or they are redirected home. */
  role?: User["role"];
  children: React.ReactNode;
}

/**
 * Client-side route guard — JWT lives in localStorage, so middleware cannot
 * read it. Calls auth.me() and redirects unauthenticated or wrong-role users.
 */
export function RequireAuth({ role, children }: RequireAuthProps) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("access_token");
    if (!token) {
      router.replace("/login");
      return;
    }
    auth
      .me()
      .then((u) => {
        if (role && u.role !== role) {
          router.replace("/");
          return;
        }
        setUser(u);
      })
      .catch(() => router.replace("/login"))
      .finally(() => setChecking(false));
  }, [role, router]);

  if (checking) {
    return <div className="px-4 py-16 text-center text-gray-500">Checking access…</div>;
  }
  if (!user) return null;
  return <>{children}</>;
}
