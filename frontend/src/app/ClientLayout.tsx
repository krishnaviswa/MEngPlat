"use client";

import { useEffect, useState } from "react";
import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { auth, type User } from "@/lib/api";

export function ClientLayout({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const token = localStorage.getItem("access_token");
    if (token) {
      auth.me().then(setUser).catch(() => setUser(null));
    }
  }, []);

  function handleLogout() {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    setUser(null);
    window.location.href = "/";
  }

  return (
    <div className="flex min-h-screen flex-col">
      <Navbar user={user} onLogout={handleLogout} />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  );
}
