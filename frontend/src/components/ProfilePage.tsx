"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Business, NationalIdType, User } from "@/lib/api";
import { auth, clearTokens, favorites } from "@/lib/api";
import { BusinessCard } from "@/components/BusinessCard";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

/**
 * Profile — editable identity/contact fields, read-only email/role/TOTP status,
 * plus customer favorites list. Re-checks auth on bfcache restore.
 */
export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [fullName, setFullName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");
  const [phone, setPhone] = useState("");
  const [addressLine1, setAddressLine1] = useState("");
  const [addressLine2, setAddressLine2] = useState("");
  const [city, setCity] = useState("");
  const [stateField, setStateField] = useState("");
  const [postalCode, setPostalCode] = useState("");
  const [country, setCountry] = useState("");
  const [nationalIdType, setNationalIdType] = useState<NationalIdType | "">("");
  const [nationalIdNumber, setNationalIdNumber] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [favoriteBusinesses, setFavoriteBusinesses] = useState<Business[]>([]);
  const [favoritesLoading, setFavoritesLoading] = useState(true);

  const applyUser = useCallback((u: User) => {
    setUser(u);
    setFullName(u.full_name);
    setAvatarUrl(u.avatar_url || "");
    setPhone(u.phone || "");
    setAddressLine1(u.address_line1 || "");
    setAddressLine2(u.address_line2 || "");
    setCity(u.city || "");
    setStateField(u.state || "");
    setPostalCode(u.postal_code || "");
    setCountry(u.country || "");
    setNationalIdType(u.national_id_type || "");
    setNationalIdNumber(u.national_id_number || "");
  }, []);

  const loadProfile = useCallback(() => {
    const token = localStorage.getItem("access_token");
    if (!token) {
      setUser(null);
      setLoading(false);
      router.replace("/login");
      return;
    }
    setLoading(true);
    auth
      .me()
      .then(applyUser)
      .catch(() => {
        clearTokens();
        setUser(null);
        router.replace("/login");
      })
      .finally(() => setLoading(false));
  }, [applyUser, router]);

  useEffect(() => {
    loadProfile();
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) loadProfile();
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, [loadProfile]);

  useEffect(() => {
    if (!user || user.role !== "customer") {
      setFavoritesLoading(false);
      return;
    }
    favorites
      .list()
      .then(setFavoriteBusinesses)
      .catch(() => setFavoriteBusinesses([]))
      .finally(() => setFavoritesLoading(false));
  }, [user]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setSuccess(null);
    setError(null);
    try {
      const updated = await auth.updateMe({
        full_name: fullName.trim(),
        avatar_url: avatarUrl.trim() || null,
        phone: phone.trim() || null,
        address_line1: addressLine1.trim() || null,
        address_line2: addressLine2.trim() || null,
        city: city.trim() || null,
        state: stateField.trim() || null,
        postal_code: postalCode.trim() || null,
        country: country.trim() || null,
        national_id_type: nationalIdType || null,
        national_id_number: nationalIdNumber.trim() || null,
      });
      applyUser(updated);
      setSuccess("Profile updated.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Update failed");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="p-8 text-center">Loading...</p>;
  if (!user) return null;

  const isPasswordAccount = Boolean(user.auth_provider !== "google" || user.totp_enabled);

  return (
    <div className="mx-auto max-w-2xl space-y-8 px-4 py-8">
      <Card>
        <h1 className="text-xl font-bold">Profile</h1>
        <form onSubmit={onSubmit} className="mt-4 space-y-4">
          <div>
            <label className="text-sm text-gray-600" htmlFor="full_name">
              Display name
            </label>
            <Input
              id="full_name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
              className="mt-1"
            />
          </div>
          <div>
            <label className="text-sm text-gray-600" htmlFor="phone">
              Mobile number
            </label>
            <Input
              id="phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+91…"
              className="mt-1"
            />
            <p className="mt-1 text-xs text-gray-500">Used for account contact. Password sign-in uses an authenticator app, not SMS.</p>
          </div>
          <div>
            <label className="text-sm text-gray-600" htmlFor="avatar_url">
              Avatar URL
            </label>
            <Input
              id="avatar_url"
              value={avatarUrl}
              onChange={(e) => setAvatarUrl(e.target.value)}
              placeholder="https://…"
              className="mt-1"
            />
          </div>

          <fieldset className="space-y-3 border-t pt-4">
            <legend className="text-sm font-medium text-gray-800">Address</legend>
            <Input
              value={addressLine1}
              onChange={(e) => setAddressLine1(e.target.value)}
              placeholder="Address line 1"
            />
            <Input
              value={addressLine2}
              onChange={(e) => setAddressLine2(e.target.value)}
              placeholder="Address line 2"
            />
            <div className="grid gap-3 sm:grid-cols-2">
              <Input value={city} onChange={(e) => setCity(e.target.value)} placeholder="City" />
              <Input value={stateField} onChange={(e) => setStateField(e.target.value)} placeholder="State" />
              <Input
                value={postalCode}
                onChange={(e) => setPostalCode(e.target.value)}
                placeholder="Postal code"
              />
              <Input value={country} onChange={(e) => setCountry(e.target.value)} placeholder="Country" />
            </div>
          </fieldset>

          <fieldset className="space-y-3 border-t pt-4">
            <legend className="text-sm font-medium text-gray-800">National ID</legend>
            <select
              value={nationalIdType}
              onChange={(e) => setNationalIdType(e.target.value as NationalIdType | "")}
              className="w-full rounded border px-3 py-2 text-sm"
            >
              <option value="">Select type</option>
              <option value="pan">PAN (India)</option>
              <option value="other">Other national ID</option>
            </select>
            <Input
              value={nationalIdNumber}
              onChange={(e) => setNationalIdNumber(e.target.value)}
              placeholder="ID number"
            />
            <p className="text-xs text-gray-500">Stored for your account only — not verified as KYC in this version.</p>
          </fieldset>

          <div className="border-t pt-4">
            <p className="text-sm text-gray-500">Email</p>
            <p className="font-medium">{user.email}</p>
            <p className="mt-1 text-xs text-gray-500">Email changes aren&apos;t supported yet.</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Role</p>
            <p className="font-medium capitalize">{user.role}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Sign-in security</p>
            {user.auth_provider === "google" && !user.totp_enabled ? (
              <p className="text-sm text-gray-700">
                You sign in with Gmail/Google. Authenticator MFA is not required on that path.
              </p>
            ) : (
              <p className="text-sm text-gray-700">
                {user.totp_enabled
                  ? "Authenticator app enabled — required for email/password sign-in."
                  : isPasswordAccount
                    ? "Authenticator setup is required the next time you sign in with your password."
                    : "Authenticator app not enabled."}
              </p>
            )}
            <p className="mt-1 text-xs text-amber-800">
              Tip: an authenticator app is more secure than password alone and helps safeguard your account.
            </p>
          </div>
          {success && <p className="text-sm text-green-700">{success}</p>}
          {error && <p className="text-sm text-red-600">{error}</p>}
          <Button type="submit" disabled={saving}>
            {saving ? "Saving…" : "Save changes"}
          </Button>
        </form>
      </Card>

      {user.role === "customer" && (
        <div>
          <h2 className="text-lg font-bold">Favorites</h2>
          {favoritesLoading ? (
            <p className="mt-2 text-sm text-gray-500">Loading favorites...</p>
          ) : favoriteBusinesses.length === 0 ? (
            <p className="mt-2 text-sm text-gray-500">
              No favorites yet —{" "}
              <a href="/search" className="text-brand-600">
                discover businesses
              </a>
            </p>
          ) : (
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              {favoriteBusinesses.map((b) => (
                <BusinessCard key={b.id} business={b} />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
