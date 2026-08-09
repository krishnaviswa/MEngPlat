"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { RatingWidget } from "./RatingWidget";
import { photos, reviews } from "@/lib/api";
import type { Business } from "@/lib/api";

const MAX_PHOTOS = 5;

interface ReviewFormProps {
  business: Business;
}

/** ReviewForm — rating/title/body/photos submission for a business. State: rating, title, body, files, error, loading. */
export function ReviewForm({ business }: ReviewFormProps) {
  const router = useRouter();
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [rating, setRating] = useState(0);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setSignedIn(!!localStorage.getItem("access_token"));
  }, []);

  function handleFiles(e: React.ChangeEvent<HTMLInputElement>) {
    const selected = Array.from(e.target.files || []).slice(0, MAX_PHOTOS);
    setFiles(selected);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (rating < 1) {
      setError("Please select a star rating");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const review = await reviews.create({
        business_id: business.id,
        rating,
        title: title || undefined,
        body,
      });

      if (files.length) {
        const uploads = await Promise.allSettled(
          files.map((file) => photos.upload(file, { reviewId: review.id, photoType: "review" }))
        );
        const failed = uploads.filter((r) => r.status === "rejected").length;
        if (failed) {
          setError(`Review posted, but ${failed} photo${failed > 1 ? "s" : ""} failed to upload.`);
        }
      }

      router.push(`/businesses/${business.slug}`);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to submit review");
    } finally {
      setLoading(false);
    }
  }

  if (signedIn === null) return null;

  if (!signedIn) {
    return (
      <div className="rounded-xl border bg-white p-6 text-center shadow-sm">
        <p className="text-gray-700">Sign in to write a review.</p>
        <a href="/login" className="mt-3 inline-block rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700">
          Sign in
        </a>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-xl border bg-white p-6 shadow-sm">
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}
      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Rating</label>
        <RatingWidget value={rating} onChange={setRating} size="lg" />
      </div>
      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Title (optional)"
        className="w-full rounded border px-3 py-2"
      />
      <textarea
        required
        minLength={10}
        value={body}
        onChange={(e) => setBody(e.target.value)}
        placeholder="Share details of your experience (min 10 characters)"
        rows={5}
        className="w-full rounded border px-3 py-2"
      />
      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Photos (optional, up to {MAX_PHOTOS})</label>
        <input type="file" accept="image/*" multiple onChange={handleFiles} className="w-full text-sm" />
        {files.length > 0 && <p className="mt-1 text-xs text-gray-500">{files.length} photo(s) selected</p>}
      </div>
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
      >
        {loading ? "Posting..." : "Post review"}
      </button>
    </form>
  );
}
