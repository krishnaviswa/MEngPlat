"use client";

import { useState } from "react";
import { Input } from "@/components/ui/Input";
import { PageHeading } from "@/components/ui/PageHeading";
import { auth } from "@/lib/api";

/** ForgotPasswordForm — email-only request. Always shows the same generic confirmation, known or unknown address. */
export function ForgotPasswordForm() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await auth.forgotPassword(email);
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }

  if (submitted) {
    return (
      <div className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
        <PageHeading size="sm">Check your email</PageHeading>
        <p className="text-sm text-muted">
          If an account exists for that email, we sent password-reset instructions.
        </p>
        <a href="/login" className="block text-sm text-brand-600 underline">
          Back to sign in
        </a>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
      <PageHeading size="sm">Forgot password</PageHeading>
      <p className="text-sm text-muted">Enter your account email and we&apos;ll send you a reset link.</p>
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}
      <Input
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
        size="md"
      />
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
      >
        {loading ? "Sending..." : "Send reset link"}
      </button>
      <a href="/login" className="block text-center text-sm text-muted underline">
        Back to sign in
      </a>
    </form>
  );
}
