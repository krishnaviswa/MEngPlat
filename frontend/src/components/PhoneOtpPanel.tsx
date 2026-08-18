"use client";

import { useState } from "react";
import { auth, redirectAfterAuth } from "@/lib/api";

/** Phone OTP sign-in — skips TOTP, same as Google. Mock SMS logs the code. */
export function PhoneOtpPanel({
  fullName,
  role,
  onError,
}: {
  fullName?: string;
  role?: string;
  onError: (message: string) => void;
}) {
  const [countryCode, setCountryCode] = useState("+91");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [roleMismatchNote, setRoleMismatchNote] = useState("");

  async function sendCode() {
    onError("");
    setBusy(true);
    try {
      await auth.phoneRequest(`${countryCode}${phone}`);
      setSent(true);
    } catch (err) {
      onError(err instanceof Error ? err.message : "Could not send code");
    } finally {
      setBusy(false);
    }
  }

  async function verify() {
    onError("");
    setRoleMismatchNote("");
    setBusy(true);
    try {
      const tokens = await auth.phoneVerify({
        phone: `${countryCode}${phone}`,
        code,
        full_name: fullName,
        role,
      });
      await redirectAfterAuth(tokens, {
        expectedRole: role,
        onRoleMismatch: (actualRole) => setRoleMismatchNote(`Signed in as ${actualRole} — this number is already registered as a ${actualRole} account.`),
      });
    } catch (err) {
      onError(err instanceof Error ? err.message : "Invalid code");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-3 rounded-lg border border-border bg-surface p-4">
      <label className="block text-sm font-medium text-ink">Continue with phone</label>
      <div className="flex gap-2">
        <select
          value={countryCode}
          onChange={(e) => setCountryCode(e.target.value)}
          disabled={sent}
          className="w-24 rounded border bg-surface-raised px-2 py-2.5 text-sm disabled:opacity-50"
          aria-label="Country code"
        >
          <option value="+91">🇮🇳 +91</option>
          <option value="+1">🇺🇸 +1</option>
        </select>
        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="Mobile number"
          disabled={sent}
          className="flex-1 rounded border bg-surface-raised px-3 py-2.5 disabled:opacity-50"
          aria-label="Mobile number"
        />
      </div>
      {sent && (
        <input
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="6-digit SMS code"
          className="w-full rounded border bg-surface-raised px-3 py-2.5 text-center text-lg tracking-widest"
          aria-label="SMS code"
        />
      )}
      {roleMismatchNote && (
        <p className="rounded bg-amber-50 p-2 text-sm text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
          {roleMismatchNote}
        </p>
      )}
      {!sent ? (
        <button
          type="button"
          disabled={busy || !phone.trim()}
          onClick={sendCode}
          className="w-full rounded border border-brand-200 py-2 text-sm text-brand-800 hover:bg-brand-50 disabled:opacity-50"
        >
          {busy ? "Sending…" : "Send SMS code"}
        </button>
      ) : (
        <button
          type="button"
          disabled={busy || code.trim().length < 4}
          onClick={verify}
          className="w-full rounded border border-brand-200 py-2 text-sm text-brand-800 hover:bg-brand-50 disabled:opacity-50"
        >
          {busy ? "Verifying…" : "Verify and sign in"}
        </button>
      )}
    </div>
  );
}
