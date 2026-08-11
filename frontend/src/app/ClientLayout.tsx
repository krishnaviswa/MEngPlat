"use client";

import { useEffect, useState } from "react";
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
    return () => window.removeEventListener("pageshow", onPageShow);
  }, []);

  async function handleLogout() {
    await performLogout("/");
  }

  return (
    <div className="flex min-h-screen flex-col">
      <Navbar user={user} onLogout={handleLogout} />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  );
}
