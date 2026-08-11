"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { auth, clearTokens, type User } from "@/lib/api";

interface RequireAuthProps {
  /** When set, user must have this role or they are redirected home. */
  role?: User["role"];
  children: React.ReactNode;
}

/**
 * Client-side route guard — JWT lives in localStorage, so middleware cannot
 * read it. Calls auth.me() and redirects unauthenticated or wrong-role users.
 * Re-checks on bfcache `pageshow` so Back after logout cannot restore access.
 */
export function RequireAuth({ role, children }: RequireAuthProps) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [checking, setChecking] = useState(true);

  const verify = useCallback(() => {
    const token = localStorage.getItem("access_token");
    if (!token) {
      setUser(null);
      setChecking(false);
      router.replace("/login");
      return;
    }
    setChecking(true);
    auth
      .me()
      .then((u) => {
        if (role && u.role !== role) {
          setUser(null);
          router.replace("/");
          return;
        }
        setUser(u);
      })
      .catch(() => {
        clearTokens();
        setUser(null);
        router.replace("/login");
      })
      .finally(() => setChecking(false));
  }, [role, router]);

  useEffect(() => {
    verify();
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) verify();
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, [verify]);

  if (checking) {
    return <div className="px-4 py-16 text-center text-gray-500">Checking access…</div>;
  }
  if (!user) return null;
  return <>{children}</>;
}
