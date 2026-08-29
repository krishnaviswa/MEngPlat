"use client";

import { ChangeEvent, FormEvent, useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { Business, NationalIdType, User, UserProfileUpdateInput } from "@/lib/api";
import { auth, clearTokens, favorites } from "@/lib/api";
import { BusinessCard } from "@/components/BusinessCard";
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { PageHeading } from "@/components/ui/PageHeading";
import { Select } from "@/components/ui/Select";

/**
 * Profile — editable identity/contact fields, read-only email/role/TOTP status,
 * plus customer favorites list. Re-checks auth on bfcache restore.
 */
export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [fullName, setFullName] = useState("");
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
  const [confirmPassword, setConfirmPassword] = useState("");
  const [favoriteBusinesses, setFavoriteBusinesses] = useState<Business[]>([]);
  const [favoritesLoading, setFavoritesLoading] = useState(true);
  const [avatarUploading, setAvatarUploading] = useState(false);
  const [avatarError, setAvatarError] = useState<string | null>(null);
  const avatarInputRef = useRef<HTMLInputElement>(null);

  const applyUser = useCallback((u: User) => {
    setUser(u);
    setFullName(u.full_name);
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

  // S-085: avatar upload applies immediately on file selection, independent
  // of the "Save changes" submit below -- this is not part of onSubmit.
  async function handleAvatarChange(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setAvatarError(null);
    setAvatarUploading(true);
    try {
      const updated = await auth.uploadAvatar(file);
      applyUser(updated);
      // Navbar (via ClientLayout) has its own independent user state -- this
      // scoped event is how it hears about the change without a reload.
      window.dispatchEvent(new CustomEvent("mh:user-updated", { detail: updated }));
    } catch (err) {
      setAvatarError(err instanceof Error ? err.message : "Upload failed");
    } finally {
      setAvatarUploading(false);
    }
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!user) return;
    setSaving(true);
    setSuccess(null);
    setError(null);
    try {
      const nextPhone = phone.trim() || null;
      const nextNid = nationalIdNumber.trim() || null;
      const phoneChanged = nextPhone !== (user.phone || null);
      const typeChanged = (nationalIdType || null) !== (user.national_id_type || null);
      const masked = Boolean(nextNid && (nextNid.includes("*") || nextNid.includes("•")));
      const nidChanged = typeChanged || (!masked && nextNid !== (user.national_id_number || null));
      let reauthToken: string | undefined;
      if (user.role === "merchant" && (phoneChanged || nidChanged)) {
        if (!confirmPassword.trim()) {
          setError("Confirm with your password so we know this change is yours.");
          setSaving(false);
          return;
        }
        const stepped = await auth.reauth({ password: confirmPassword.trim() });
        reauthToken = stepped.reauth_token;
      }
      const payload: UserProfileUpdateInput = {
          full_name: fullName.trim(),
          phone: nextPhone,
          address_line1: addressLine1.trim() || null,
          address_line2: addressLine2.trim() || null,
          city: city.trim() || null,
          state: stateField.trim() || null,
          postal_code: postalCode.trim() || null,
          country: country.trim() || null,
          national_id_type: nationalIdType || null,
      };
      if (!masked) payload.national_id_number = nextNid;
      const updated = await auth.updateMe(payload, reauthToken);
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
        <PageHeading size="sm">Profile</PageHeading>

        <div className="mt-4 flex flex-col items-center gap-2">
          <button
            type="button"
            onClick={() => avatarInputRef.current?.click()}
            disabled={avatarUploading}
            aria-label="Change profile photo"
            className="group relative overflow-hidden rounded-full disabled:cursor-not-allowed disabled:opacity-70"
          >
            <Avatar user={user} size="lg" />
            {avatarUploading ? (
              <span className="absolute inset-0 flex items-center justify-center rounded-full bg-black/50 text-xs font-medium text-white">
                Uploading…
              </span>
            ) : (
              <span className="absolute inset-0 flex items-center justify-center rounded-full bg-black/0 text-xs font-medium text-white opacity-0 transition group-hover:bg-black/50 group-hover:opacity-100">
                Change photo
              </span>
            )}
          </button>
          <input
            ref={avatarInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif"
            hidden
            onChange={handleAvatarChange}
          />
          {avatarError && <p className="text-sm text-red-600">{avatarError}</p>}
        </div>

        <form onSubmit={onSubmit} className="mt-4 space-y-4">
          <div>
            <label className="text-sm text-muted" htmlFor="full_name">
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
            <label className="text-sm text-muted" htmlFor="phone">
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
            <p className="mt-1 text-xs text-muted">Used for account contact. Password sign-in uses an authenticator app, not SMS.</p>
          </div>
          <fieldset className="space-y-3 border-t pt-4">
            <legend className="text-sm font-medium text-ink">Address</legend>
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
            <legend className="text-sm font-medium text-ink">National ID</legend>
            <Select
              value={nationalIdType}
              onChange={(e) => setNationalIdType(e.target.value as NationalIdType | "")}
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
            />
            <p className="text-xs text-muted">
              {user.role === "merchant"
                ? "Required before listing. Changing phone or ID asks you to confirm with your password."
                : "Optional. Stored for your account only — not verified as KYC in this version."}
            </p>
          </fieldset>

          {user.role === "merchant" && (
            <label className="block border-t pt-4">
              <span className="text-sm text-muted">Confirm with password (phone or national ID changes)</span>
              <Input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                aria-label="Confirm with password"
                className="mt-1"
              />
            </label>
          )}

          <div className="border-t pt-4">
            <p className="text-sm text-muted">Email</p>
            <p className="font-medium">{user.email}</p>
            <p className="mt-1 text-xs text-muted">Email changes aren&apos;t supported yet.</p>
          </div>
          <div>
            <p className="text-sm text-muted">Role</p>
            <p className="font-medium capitalize">{user.role}</p>
          </div>
          <div>
            <p className="text-sm text-muted">Sign-in security</p>
            {user.auth_provider === "google" && !user.totp_enabled ? (
              <p className="text-sm text-muted">
                You sign in with Gmail/Google. Authenticator MFA is not required on that path.
              </p>
            ) : (
              <p className="text-sm text-muted">
                {user.totp_enabled
                  ? "Authenticator app enabled — required for email/password sign-in."
                  : isPasswordAccount
                    ? "Authenticator setup is required the next time you sign in with your password."
                    : "Authenticator app not enabled."}
              </p>
            )}
            <p className="mt-1 text-xs text-amber-800 dark:text-amber-400">
              Tip: an authenticator app is more secure than password alone and helps safeguard your account.
            </p>
          </div>
          {success && <p className="text-sm text-green-700 dark:text-green-400">{success}</p>}
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
            <p className="mt-2 text-sm text-muted">Loading favorites...</p>
          ) : favoriteBusinesses.length === 0 ? (
            <p className="mt-2 text-sm text-muted">
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
