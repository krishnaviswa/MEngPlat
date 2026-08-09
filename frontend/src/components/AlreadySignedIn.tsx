"use client";

import { useEffect, useState } from "react";
import { auth } from "@/lib/api";
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
    const token = localStorage.getItem("access_token");
    if (!token) {
      setChecked(true);
      return;
    }
    auth
      .me()
      .then(setUser)
      .catch(() => setUser(null))
      .finally(() => setChecked(true));
  }, []);

  async function handleLogout() {
    try {
      await auth.logout();
    } catch {
      // best-effort server-side revoke; local logout proceeds regardless
    }
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    window.location.href = "/login";
  }

  if (!checked) return null;

  if (!user) return <>{children}</>;

  return (
    <div className="mx-auto max-w-md space-y-4 rounded-xl border bg-white p-6 text-center shadow-sm">
      <p className="text-gray-700">
        You&apos;re signed in as <span className="font-medium">{user.full_name}</span> ({user.role}).
      </p>
      <div className="flex justify-center gap-3">
        <a href="/" className="rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700">
          Continue
        </a>
        <button onClick={handleLogout} className="rounded border px-4 py-2 hover:bg-gray-50">
          Log out to sign in as someone else
        </button>
      </div>
    </div>
  );
}
