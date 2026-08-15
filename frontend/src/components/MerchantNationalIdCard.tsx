"use client";

import { FormEvent, useState } from "react";
import { auth, type NationalIdType, type User } from "@/lib/api";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";

function hasId(user: User): boolean {
  return Boolean(user.national_id_type && user.national_id_number?.trim());
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
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const complete = hasId(user);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    try {
      const updated = await auth.updateMe({
        national_id_type: nationalIdType || null,
        national_id_number: nationalIdNumber.trim() || null,
      });
      onSaved(updated);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="rounded-xl border bg-surface-raised p-4">
      <h3 className="font-semibold">National ID</h3>
      <p className="mt-1 text-sm text-muted">
        Required for shop owners before you submit a listing. Stored on your account — not verified as government
        KYC.
      </p>
      {!complete && (
        <p className="mt-2 text-sm text-amber-800 dark:text-amber-400">Add PAN, Aadhaar, or another national ID to create listings.</p>
      )}
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
        <Input
          value={nationalIdNumber}
          onChange={(e) => setNationalIdNumber(e.target.value)}
          placeholder="ID number"
          aria-label="National ID number"
        />
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button
          type="submit"
          disabled={saving}
          className="rounded bg-brand-600 px-3 py-1.5 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {saving ? "Saving…" : "Save national ID"}
        </button>
      </form>
    </section>
  );
}
