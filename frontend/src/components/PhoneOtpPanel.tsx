"use client";

import { useState } from "react";
import { auth, storeTokens } from "@/lib/api";

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
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);

  async function sendCode() {
    onError("");
    setBusy(true);
    try {
      await auth.phoneRequest(phone);
      setSent(true);
    } catch (err) {
      onError(err instanceof Error ? err.message : "Could not send code");
    } finally {
      setBusy(false);
    }
  }

  async function verify() {
    onError("");
    setBusy(true);
    try {
      const tokens = await auth.phoneVerify({
        phone,
        code,
        full_name: fullName,
        role,
      });
      storeTokens(tokens);
      window.location.href = "/";
    } catch (err) {
      onError(err instanceof Error ? err.message : "Invalid code");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-gray-800">Continue with phone</p>
      <input
        type="tel"
        value={phone}
        onChange={(e) => setPhone(e.target.value)}
        placeholder="Mobile number"
        className="w-full rounded border px-3 py-2"
        aria-label="Mobile number"
      />
      {sent && (
        <input
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="6-digit SMS code"
          className="w-full rounded border px-3 py-2"
          aria-label="SMS code"
        />
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
