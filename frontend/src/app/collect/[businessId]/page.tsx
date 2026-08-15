"use client";

import { use, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { auth, businesses, reviews } from "@/lib/api";
import type { Business } from "@/lib/api";

/** Public review-collection wizard. All star ratings continue equally — no low-star intercept. */
export default function CollectReviewPage({ params }: { params: Promise<{ businessId: string }> }) {
  const { businessId } = use(params);
  const router = useRouter();
  const [step, setStep] = useState<"stars" | "text" | "done">("stars");
  const [rating, setRating] = useState(0);
  const [body, setBody] = useState("");
  const [error, setError] = useState("");
  const [business, setBusiness] = useState<Business | null>(null);

  useEffect(() => {
    businesses
      .list()
      .then((list) => setBusiness(list.find((b) => b.id === businessId) ?? null))
      .catch(() => setBusiness(null));
  }, [businessId]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    try {
      await auth.me();
    } catch {
      router.push(`/login?next=/collect/${businessId}`);
      return;
    }
    try {
      await reviews.create({ business_id: businessId, rating, body });
      setStep("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not submit review");
    }
  }

  const mapsHref = business
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${business.name} ${business.city}`)}`
    : "#";

  return (
    <div className="mx-auto max-w-lg px-4 py-10">
      <h1 className="text-2xl font-bold">{business?.name ?? "Leave a review"}</h1>
      <p className="mt-1 text-sm text-gray-600">Every star rating is collected the same way. Nothing is hidden for low scores.</p>

      {step === "stars" && (
        <div className="mt-6 space-y-4">
          <RatingWidget value={rating} onChange={setRating} />
          <button
            type="button"
            disabled={rating < 1}
            onClick={() => setStep("text")}
            className="rounded bg-brand-600 px-4 py-2 text-sm text-white disabled:opacity-50"
          >
            Continue
          </button>
        </div>
      )}

      {step === "text" && (
        <form onSubmit={submit} className="mt-6 space-y-3">
          <textarea
            required
            minLength={10}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="w-full rounded border p-2 text-sm"
            rows={5}
            placeholder="What stood out? (at least 10 characters)"
          />
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button type="submit" className="rounded bg-brand-600 px-4 py-2 text-sm text-white">
            Submit review
          </button>
        </form>
      )}

      {step === "done" && (
        <div className="mt-6 space-y-3 text-sm">
          <p>Thank you. Your review is in MerchantHub.</p>
          <a href={mapsHref} className="text-brand-700 underline" target="_blank" rel="noreferrer">
            Optional: also leave a Google Maps review (suggestion, not required)
          </a>
        </div>
      )}
    </div>
  );
}
