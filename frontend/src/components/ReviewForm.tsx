"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { RatingWidget } from "./ui/RatingWidget";
import { API_URL, photos, reviews } from "@/lib/api";
import type { Business, Review } from "@/lib/api";

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
  const [submitted, setSubmitted] = useState<Review | null>(null);

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
          files.map((file) => photos.upload(file, { reviewId: review.id, photoType: "review" })),
        );
        const failed = uploads.filter((r) => r.status === "rejected").length;
        if (failed) {
          setError(`Review posted, but ${failed} photo${failed > 1 ? "s" : ""} failed to upload.`);
        }
      }

      setSubmitted(review);
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
      <div className="rounded-xl border bg-surface-raised p-6 text-center shadow-sm">
        <p className="text-muted">Sign in to write a review.</p>
        <a href="/login" className="mt-3 inline-block rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700">
          Sign in
        </a>
      </div>
    );
  }

  if (submitted) {
    const held = submitted.status === "reported";
    return (
      <div className="rounded-xl border border-border bg-surface-raised p-6 text-center shadow-sm">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-2xl text-green-600">
          ✓
        </div>
        {held ? (
          <>
            <p className="mt-3 text-lg font-semibold">Thanks — we received your review.</p>
            <p className="mt-1 text-sm text-muted">
              It is held for admin review because the text may not meet our content rules. It is not live on
              the listing yet.
            </p>
          </>
        ) : (
          <>
            <p className="mt-3 text-lg font-semibold">Thank you! Your review is live.</p>
            <p className="mt-1 text-sm text-muted">
              It is on {business.name} now. No merchant or admin approval is required.
            </p>
          </>
        )}
        {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
        <a
          href={`/businesses/${business.slug}`}
          className="mt-4 inline-block rounded bg-brand-600 px-4 py-2 text-sm text-white hover:bg-brand-700"
        >
          Back to {business.name}
        </a>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-xl border bg-surface-raised p-6 shadow-sm">
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}
      <div className="flex items-center gap-3">
        {(business.storefront_url || business.logo_url) && (
          <img
            src={(() => {
              const url = business.storefront_url || business.logo_url || "";
              return url.startsWith("http") ? url : `${API_URL}${url}`;
            })()}
            alt=""
            className="h-14 w-14 rounded-lg object-cover"
          />
        )}
        <div>
          <p className="font-semibold">{business.name}</p>
          <p className="text-sm text-muted">{[business.address, business.city].filter(Boolean).join(", ")}</p>
        </div>
      </div>
      <div>
        <label className="mb-1 block text-sm font-medium text-muted">Rating</label>
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
        <label className="mb-1 block text-sm font-medium text-muted">Photos (optional, up to {MAX_PHOTOS})</label>
        <input type="file" accept="image/*" multiple onChange={handleFiles} className="w-full text-sm" />
        {files.length > 0 && <p className="mt-1 text-xs text-muted">{files.length} photo(s) selected</p>}
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
