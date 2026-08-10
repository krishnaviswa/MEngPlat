"use client";

import { FormEvent, useEffect, useState } from "react";
import type { Business, User } from "@/lib/api";
import { auth, favorites } from "@/lib/api";
import { BusinessCard } from "@/components/BusinessCard";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

/**
 * Profile — editable name/avatar, read-only email/role, plus customer favorites list.
 */
export default function ProfilePage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [fullName, setFullName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [favoriteBusinesses, setFavoriteBusinesses] = useState<Business[]>([]);
  const [favoritesLoading, setFavoritesLoading] = useState(true);

  useEffect(() => {
    auth
      .me()
      .then((u) => {
        setUser(u);
        setFullName(u.full_name);
        setAvatarUrl(u.avatar_url || "");
      })
      .catch(() => setUser(null))
      .finally(() => setLoading(false));
  }, []);

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
        avatar_url: avatarUrl.trim() || undefined,
      });
      setUser(updated);
      setFullName(updated.full_name);
      setAvatarUrl(updated.avatar_url || "");
      setSuccess("Profile updated.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Update failed");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="p-8 text-center">Loading...</p>;
  if (!user)
    return (
      <p className="p-8 text-center">
        Please{" "}
        <a href="/login" className="text-brand-600">
          login
        </a>
        .
      </p>
    );

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
          <div>
            <p className="text-sm text-gray-500">Email</p>
            <p className="font-medium">{user.email}</p>
            <p className="mt-1 text-xs text-gray-500">Email changes aren&apos;t supported yet.</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Role</p>
            <p className="font-medium capitalize">{user.role}</p>
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
