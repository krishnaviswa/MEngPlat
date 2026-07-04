"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { auth } from "@/lib/api";

/** RegisterForm — account creation with role selection. State: form fields, error, loading. */
export function RegisterForm() {
  const router = useRouter();
  const [form, setForm] = useState({
    email: "",
    full_name: "",
    password: "",
    role: "customer",
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await auth.register(form);
      const tokens = await auth.login({ email: form.email, password: form.password });
      localStorage.setItem("access_token", tokens.access_token);
      localStorage.setItem("refresh_token", tokens.refresh_token);
      router.push(form.role === "merchant" ? "/merchant/dashboard" : "/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border bg-white p-6 shadow-sm">
      <h1 className="text-xl font-bold">Create account</h1>
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}
      <input
        required
        value={form.full_name}
        onChange={(e) => setForm({ ...form, full_name: e.target.value })}
        placeholder="Full name"
        className="w-full rounded border px-3 py-2"
      />
      <input
        type="email"
        required
        value={form.email}
        onChange={(e) => setForm({ ...form, email: e.target.value })}
        placeholder="Email"
        className="w-full rounded border px-3 py-2"
      />
      <input
        type="password"
        required
        minLength={8}
        value={form.password}
        onChange={(e) => setForm({ ...form, password: e.target.value })}
        placeholder="Password (min 8 chars)"
        className="w-full rounded border px-3 py-2"
      />
      <select
        value={form.role}
        onChange={(e) => setForm({ ...form, role: e.target.value })}
        className="w-full rounded border px-3 py-2"
      >
        <option value="customer">Customer — discover & review</option>
        <option value="merchant">Merchant — list my business</option>
      </select>
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
      >
        {loading ? "Creating..." : "Sign up"}
      </button>
    </form>
  );
}
