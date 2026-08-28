"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import { auth, nationalId, type NationalIdType, type User } from "@/lib/api";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";

function hasId(user: User): boolean {
  return Boolean(user.national_id_type && user.national_id_number?.trim());
}

/** Mask all but the last 4 characters, e.g. "ABCDE1234F" -> "••••••1234F". Display-only. */
function maskNationalId(value: string): string {
  if (value.length <= 4) return "•".repeat(value.length);
  return "•".repeat(value.length - 4) + value.slice(-4);
}

/** Structural format only -- not a government checksum. Mirrors backend's schema-level regexes (S-070/ADR-013). */
const PAN_FORMAT = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
const AADHAAR_FORMAT = /^\d{12}$/;

function formatError(type: NationalIdType | "", value: string): string {
  const trimmed = value.trim();
  if (type === "aadhaar" && !AADHAAR_FORMAT.test(trimmed)) return "Aadhaar must be exactly 12 digits.";
  if (type === "pan" && !PAN_FORMAT.test(trimmed.toUpperCase())) {
    return "PAN must be 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).";
  }
  return "";
}

/** Merchant dashboard — required national ID before listing submit. Not government KYC. */
export function MerchantNationalIdCard({
  user,
  onSaved,
}: {
  user: User;
  onSaved: (u: User) => void;
}) {
  const [nationalIdType, setNationalIdType] = useState<NationalIdType | "">(user.national_id_type || "");
  const [nationalIdNumber, setNationalIdNumber] = useState(user.national_id_number || "");
  const [revealed, setRevealed] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [otpPending, setOtpPending] = useState(false);
  const [otpCode, setOtpCode] = useState("");
  const [devCode, setDevCode] = useState<string | null>(null);
  const [confirmPassword, setConfirmPassword] = useState("");
  const complete = hasId(user);

  const applyUser = useCallback((u: User) => {
    setNationalIdType(u.national_id_type || "");
    setNationalIdNumber(u.national_id_number || "");
    setRevealed(false); // re-hide after any resync, including a fresh save
    setOtpPending(false);
    setOtpCode("");
    setDevCode(null);
  }, []);

  // Resync whenever the parent hands us a new `user` object (post-save,
  // post-refetch-on-navigate-back) -- a one-time useState initializer would
  // never pick up a fresh value after the first mount.
  useEffect(() => {
    applyUser(user);
  }, [user, applyUser]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    const fmtError = formatError(nationalIdType, nationalIdNumber);
    if (fmtError) {
      setError(fmtError);
      return;
    }

    // Aadhaar saves only via the mock OTP step below -- never persisted directly (AC3/AC6).
    if (nationalIdType === "aadhaar") {
      setSaving(true);
      try {
        const res = await nationalId.requestAadhaarMockOtp(nationalIdNumber.trim());
        setOtpPending(true);
        setDevCode(res.dev_code ?? null);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Could not start verification");
      } finally {
        setSaving(false);
      }
      return;
    }

    setSaving(true);
    try {
      if (!confirmPassword.trim()) {
        setError("Confirm with your password so we know this change is yours.");
        setSaving(false);
        return;
      }
      const stepped = await auth.reauth({ password: confirmPassword.trim() });
      const updated = await auth.updateMe(
        {
          national_id_type: nationalIdType || null,
          national_id_number: nationalIdNumber.trim() || null,
        },
        stepped.reauth_token,
      );
      onSaved(updated);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  async function onVerifyOtp(e: FormEvent) {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      await nationalId.verifyAadhaarMockOtp(otpCode.trim());
      const updated = await auth.me();
      onSaved(updated);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Invalid or expired code");
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="rounded-xl border border-border bg-surface-raised p-4">
      <h3 className="font-semibold">National ID</h3>
      <p className="mt-1 text-sm text-muted">
        Required for shop owners before you submit a listing. Stored on your account — not verified as government
        KYC.
      </p>
      {!complete && (
        <p className="mt-2 text-sm text-amber-800 dark:text-amber-400">Add PAN, Aadhaar, or another national ID to create listings.</p>
      )}

      {otpPending ? (
        <form onSubmit={onVerifyOtp} className="mt-3 space-y-3">
          <p className="rounded border border-amber-300 bg-amber-50 p-2 text-xs font-medium text-amber-800 dark:border-amber-800 dark:bg-amber-900/30 dark:text-amber-300">
            Mock/demo verification — not a real government check.
          </p>
          <label className="block">
            <span className="text-sm text-muted">Enter the 6-digit code sent to your Aadhaar-linked mobile</span>
            <Input
              value={otpCode}
              onChange={(e) => setOtpCode(e.target.value)}
              placeholder="123456"
              aria-label="Mock Aadhaar OTP code"
              className="mt-1"
            />
          </label>
          {devCode && (
            <p className="text-xs text-muted">Dev mode: mock code is <span className="font-mono">{devCode}</span>.</p>
          )}
          {error && <p className="text-sm text-red-600">{error}</p>}
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={saving}
              className="rounded bg-brand-600 px-3 py-1.5 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
            >
              {saving ? "Verifying…" : "Verify"}
            </button>
            <button
              type="button"
              onClick={() => {
                setOtpPending(false);
                setOtpCode("");
                setError("");
              }}
              className="rounded border border-border px-3 py-1.5 text-sm hover:bg-surface"
            >
              Cancel
            </button>
          </div>
        </form>
      ) : (
        <form onSubmit={onSubmit} className="mt-3 space-y-3">
          <Select
            value={nationalIdType}
            onChange={(e) => setNationalIdType(e.target.value as NationalIdType | "")}
            aria-label="National ID type"
          >
            <option value="">Select type</option>
            <option value="pan">PAN (India)</option>
            <option value="aadhaar">Aadhaar (India)</option>
            <option value="other">Other national ID</option>
          </Select>
          {nationalIdType === "aadhaar" && (
            <p className="text-xs font-medium text-amber-800 dark:text-amber-400">
              Mock/demo verification — a fake OTP step follows, not a real government check.
            </p>
          )}
          <div className="flex gap-2">
            <Input
              value={complete && !revealed ? maskNationalId(nationalIdNumber) : nationalIdNumber}
              onChange={(e) => setNationalIdNumber(e.target.value)}
              readOnly={complete && !revealed}
              placeholder="ID number"
              aria-label="National ID number"
              className="flex-1"
            />
            {complete && (
              <button
                type="button"
                onClick={() => setRevealed((r) => !r)}
                className="shrink-0 rounded border border-border px-3 py-1.5 text-sm hover:bg-surface"
                aria-label={revealed ? "Hide national ID number" : "Reveal national ID number"}
              >
                {revealed ? "Hide" : "Show"}
              </button>
            )}
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          {nationalIdType !== "aadhaar" && (
            <label className="block">
              <span className="text-sm text-muted">Confirm with password</span>
              <Input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                aria-label="Confirm with password"
                className="mt-1"
              />
            </label>
          )}
          <button
            type="submit"
            disabled={saving}
            className="rounded bg-brand-600 px-3 py-1.5 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
          >
            {saving
              ? nationalIdType === "aadhaar"
                ? "Sending code…"
                : "Saving…"
              : nationalIdType === "aadhaar"
                ? "Send verification code"
                : "Save national ID"}
          </button>
        </form>
      )}
    </section>
  );
}
