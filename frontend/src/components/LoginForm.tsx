"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { auth } from "@/lib/api";

/** LoginForm — email/password login. State: email, password, error, loading. Hooks: useState, useRouter. */
export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const tokens = await auth.login({ email, password });
      localStorage.setItem("access_token", tokens.access_token);
      localStorage.setItem("refresh_token", tokens.refresh_token);
      router.push("/");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border bg-white p-6 shadow-sm">
      <h1 className="text-xl font-bold">Login</h1>
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}
      <input
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
        className="w-full rounded border px-3 py-2"
      />
      <input
        type="password"
        required
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
        className="w-full rounded border px-3 py-2"
      />
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
      >
        {loading ? "Signing in..." : "Sign in"}
      </button>
      <p className="text-center text-sm text-gray-500">
        <button type="button" className="text-brand-600 underline" disabled title="OAuth placeholder">
          Continue with Google (placeholder)
        </button>
      </p>
    </form>
  );
}
