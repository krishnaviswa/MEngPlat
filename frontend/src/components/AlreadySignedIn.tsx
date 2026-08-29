"use client";

import { useEffect, useState } from "react";
import { auth, clearTokens, performLogout, roleLandingPath } from "@/lib/api";
import type { User } from "@/lib/api";

/**
 * AlreadySignedIn — wraps LoginForm/RegisterForm so an authenticated visitor
 * sees who they're signed in as instead of a form that would silently swap
 * the active session's tokens out from under them.
 */
export function AlreadySignedIn({ children }: { children: React.ReactNode }) {
  const [checked, setChecked] = useState(false);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    function check() {
      const token = localStorage.getItem("access_token");
      if (!token) {
        setUser(null);
        setChecked(true);
        return;
      }
      auth
        .me()
        .then(setUser)
        .catch(() => {
          clearTokens();
          setUser(null);
        })
        .finally(() => setChecked(true));
    }

    check();
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) check();
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, []);

  async function handleLogout() {
    await performLogout("/login");
  }

  if (!checked) return null;

  if (!user) return <>{children}</>;

  return (
    <div className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 text-center shadow-sm">
      <p className="text-muted">
        You&apos;re signed in as <span className="font-medium">{user.full_name}</span> ({user.role}).
      </p>
      <div className="flex justify-center gap-3">
        <a
          href={roleLandingPath(user.role)}
          className="rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700"
        >
          Continue
        </a>
        <button onClick={handleLogout} className="rounded border border-border px-4 py-2 hover:bg-surface">
          Log out to sign in as someone else
        </button>
      </div>
    </div>
  );
}
