"use client";

import { useEffect, useState } from "react";
import { ThemeProvider } from "next-themes";
import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { auth, clearTokens, performLogout, type User } from "@/lib/api";

export function ClientLayout({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    function loadUser() {
      const token = localStorage.getItem("access_token");
      if (!token) {
        setUser(null);
        return;
      }
      auth
        .me()
        .then(setUser)
        .catch(() => {
          clearTokens();
          setUser(null);
        });
    }

    loadUser();

    // bfcache restore after logout can bring back a signed-in shell — re-check.
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) loadUser();
    };
    window.addEventListener("pageshow", onPageShow);

    // S-085: ProfilePage's avatar upload applies immediately and independent
    // of any page reload/navigation -- this is the small, scoped sync
    // mechanism (no shared user store today) that lets the Navbar's avatar
    // update right away too.
    const onUserUpdated = (e: Event) => {
      const detail = (e as CustomEvent<User>).detail;
      if (detail) setUser(detail);
    };
    window.addEventListener("mh:user-updated", onUserUpdated);

    return () => {
      window.removeEventListener("pageshow", onPageShow);
      window.removeEventListener("mh:user-updated", onUserUpdated);
    };
  }, []);

  async function handleLogout() {
    await performLogout("/");
  }

  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <div className="flex min-h-screen flex-col">
        <Navbar user={user} onLogout={handleLogout} />
        <main className="flex-1">{children}</main>
        <Footer />
      </div>
    </ThemeProvider>
  );
}
