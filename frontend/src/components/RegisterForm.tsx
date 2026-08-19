"use client";

import { useState } from "react";
import { AuthMethodToggle, type AuthMethod } from "@/components/AuthMethodToggle";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";
import { PhoneOtpPanel } from "@/components/PhoneOtpPanel";
import { Select } from "@/components/ui/Select";
import { auth, storeTokens } from "@/lib/api";

/** RegisterForm — account creation with role selection. State: form fields, error, loading. */
export function RegisterForm() {
  const [form, setForm] = useState({
    email: "",
    full_name: "",
    password: "",
    role: "customer",
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [authMethod, setAuthMethod] = useState<AuthMethod>("authenticator");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await auth.register(form);
      // Password accounts must enroll an authenticator on first login — send
      // them to /login rather than storing a half-finished session.
      window.location.href = `/login?registered=1&email=${encodeURIComponent(form.email)}`;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogleCredential(credential: string) {
    setError("");
    try {
      // Google quick sign-up always creates a customer account -- there's no
      // way to convey a merchant-role choice through the ID-token exchange,
      // matching how the backend's /auth/google new-account path decides role.
      const tokens = await auth.google({ credential });
      storeTokens(tokens);
      window.location.href = "/";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Google sign-in failed");
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border bg-surface-raised p-6 shadow-sm">
      <h1 className="text-xl font-bold">Create account</h1>
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}
      <input
        required
        value={form.full_name}
        onChange={(e) => setForm({ ...form, full_name: e.target.value })}
        placeholder="Full name"
        className="w-full rounded border px-3 py-2"
      />
      <Select
        aria-label="Account type"
        value={form.role}
        onChange={(e) => setForm({ ...form, role: e.target.value })}
      >
        <option value="customer">Customer — discover & review</option>
        <option value="merchant">Merchant — list my business</option>
      </Select>
      <AuthMethodToggle value={authMethod} onChange={setAuthMethod} legend="Create account with" />
      {authMethod === "authenticator" ? (
        <>
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
            minLength={12}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            placeholder="Password (min 12 chars, include a letter and a digit)"
            className="w-full rounded border px-3 py-2"
          />
          <p className="text-xs text-muted">
            After sign-up you will set up an authenticator app (required for email/password sign-in).
            Gmail sign-in below skips that step.
          </p>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
          >
            {loading ? "Creating..." : "Sign up"}
          </button>
          <div className="flex items-center gap-3 text-xs text-muted">
            <div className="h-px flex-1 bg-border" />
            or
            <div className="h-px flex-1 bg-border" />
          </div>
          <GoogleSignInButton onCredential={handleGoogleCredential} />
        </>
      ) : (
        <>
          <p className="text-xs text-muted">
            First-time Mobile OTP needs the name above. Admins cannot be created here.
          </p>
          <PhoneOtpPanel fullName={form.full_name} role={form.role} onError={setError} />
        </>
      )}
    </form>
  );
}
