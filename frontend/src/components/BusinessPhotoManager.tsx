"use client";

import { useEffect, useState } from "react";
import { photos, type Photo } from "@/lib/api";

interface BusinessPhotoManagerProps {
  businessId: string;
}

/**
 * BusinessPhotoManager — merchant-facing upload/delete control for a business's
 * public-profile photos (S-075). Optional: no validation blocks form submission
 * elsewhere on account of missing photos.
 */
export function BusinessPhotoManager({ businessId }: BusinessPhotoManagerProps) {
  const [items, setItems] = useState<Photo[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    photos
      .listForBusiness(businessId)
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, [businessId]);

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setError("");
    setUploading(true);
    try {
      const uploaded = await photos.upload(file, { businessId, photoType: "gallery" });
      setItems((prev) => [...prev, uploaded]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  }

  async function handleDelete(photoId: string) {
    if (!window.confirm("Remove this photo?")) return;
    setError("");
    try {
      await photos.delete(photoId);
      setItems((prev) => prev.filter((p) => p.id !== photoId));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Delete failed");
    }
  }

  return (
    <div className="space-y-3 rounded-xl border bg-surface-raised p-4">
      <div>
        <h3 className="text-sm font-semibold text-ink">Public profile photos</h3>
        <p className="text-xs text-muted">Optional — shown on your business's public listing.</p>
      </div>

      {error && <p className="rounded bg-red-50 p-2 text-xs text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}

      {!loading && items.length > 0 && (
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
          {items.map((photo) => (
            <div key={photo.id} className="group relative overflow-hidden rounded-lg">
              <img src={photo.url} alt={photo.caption ?? "Business photo"} className="h-24 w-full object-cover" />
              <button
                type="button"
                onClick={() => handleDelete(photo.id)}
                className="absolute right-1 top-1 rounded bg-black/60 px-2 py-0.5 text-xs text-white opacity-0 transition group-hover:opacity-100"
                aria-label="Remove photo"
              >
                Remove
              </button>
            </div>
          ))}
        </div>
      )}

      <label className="inline-block w-fit cursor-pointer rounded border border-brand-200 bg-brand-50 px-4 py-2 text-sm font-medium text-brand-800 hover:bg-brand-100 disabled:opacity-50 dark:border-brand-800 dark:bg-brand-900/30 dark:text-brand-300 dark:hover:bg-brand-900/50">
        {uploading ? "Uploading…" : "Add photo"}
        <input type="file" accept="image/*" className="hidden" disabled={uploading} onChange={handleUpload} />
      </label>
    </div>
  );
}
