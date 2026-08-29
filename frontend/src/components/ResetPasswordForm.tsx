"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Input } from "@/components/ui/Input";
import { PageHeading } from "@/components/ui/PageHeading";
import { auth } from "@/lib/api";

/** ResetPasswordForm — new password + confirm, using the `token` query param from the reset email. */
export function ResetPasswordForm() {
  const searchParams = useSearchParams();
  const token = searchParams.get("token") || "";
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [done, setDone] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (newPassword !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }
    setLoading(true);
    try {
      await auth.resetPassword(token, newPassword);
      setDone(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Reset failed");
    } finally {
      setLoading(false);
    }
  }

  if (!token) {
    return (
      <div className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
        <PageHeading size="sm">Invalid reset link</PageHeading>
        <p className="text-sm text-muted">
          This link is missing its reset token. Request a new one from the forgot-password page.
        </p>
        <a href="/forgot-password" className="block text-sm text-brand-600 underline">
          Request a new link
        </a>
      </div>
    );
  }

  if (done) {
    return (
      <div className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
        <PageHeading size="sm">Password updated</PageHeading>
        <p className="text-sm text-muted">Sign in with your new password.</p>
        <a href="/login" className="block rounded bg-brand-600 py-2 text-center text-white hover:bg-brand-700">
          Go to sign in
        </a>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
      <PageHeading size="sm">Reset password</PageHeading>
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}
      <Input
        type="password"
        required
        minLength={12}
        value={newPassword}
        onChange={(e) => setNewPassword(e.target.value)}
        placeholder="New password"
        size="md"
      />
      <Input
        type="password"
        required
        minLength={12}
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        placeholder="Confirm new password"
        size="md"
      />
      <p className="text-xs text-muted">At least 12 characters, with at least one letter and one digit.</p>
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
      >
        {loading ? "Updating..." : "Update password"}
      </button>
    </form>
  );
}
