"use client";

import { use, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { generateDraft } from "@/components/collect/DraftEngine";
import { API_URL, auth, businesses, reviews } from "@/lib/api";
import type { Business, Review } from "@/lib/api";

const CHIPS = ["Service", "Quality", "Value", "Atmosphere", "Cleanliness", "Speed"];

function resolveUrl(url: string): string {
  return url.startsWith("http") ? url : `${API_URL}${url}`;
}

/** Public review-collection hub. All star ratings continue equally — no low-star intercept. */
export default function CollectReviewPage({ params }: { params: Promise<{ businessId: string }> }) {
  const { businessId } = use(params);
  const router = useRouter();
  const [step, setStep] = useState<"stars" | "text" | "done">("stars");
  const [rating, setRating] = useState(0);
  const [selectedChips, setSelectedChips] = useState<string[]>([]);
  const [body, setBody] = useState("");
  const [error, setError] = useState("");
  const [business, setBusiness] = useState<Business | null>(null);
  const [recentReviews, setRecentReviews] = useState<Review[]>([]);

  useEffect(() => {
    businesses
      .list()
      .then((list) => {
        const match = list.find((b) => b.id === businessId) ?? null;
        setBusiness(match);
        return match ? reviews.list(match.id) : [];
      })
      .then((list) => setRecentReviews(list.slice(0, 2)))
      .catch(() => setBusiness(null));
  }, [businessId]);

  function toggleChip(chip: string) {
    setSelectedChips((prev) => (prev.includes(chip) ? prev.filter((c) => c !== chip) : [...prev, chip]));
  }

  function fillDraft() {
    setBody(
      generateDraft({
        rating,
        chips: selectedChips,
        businessName: business?.name ?? "this place",
        category: business?.categories?.[0]?.name,
        city: business?.city,
      }),
    );
  }

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

  const heroImageUrl = business?.storefront_url || business?.logo_url;
  const heroImage = heroImageUrl ? resolveUrl(heroImageUrl) : null;
  const placeLine = [business?.address, business?.city].filter(Boolean).join(", ");

  return (
    <div className="mx-auto max-w-lg px-4 pb-16">
      <div
        className="relative -mx-4 flex h-48 flex-col justify-end bg-gradient-to-br from-brand-600 to-brand-800 px-4 pb-4 text-white sm:mx-0 sm:h-56 sm:rounded-b-xl"
        style={
          heroImage
            ? { backgroundImage: `linear-gradient(to top, rgba(15,23,42,0.75), rgba(15,23,42,0.15)), url(${heroImage})`, backgroundSize: "cover", backgroundPosition: "center" }
            : undefined
        }
      >
        {business?.categories?.[0]?.name && (
          <span className="mb-1 w-fit rounded-full bg-white/20 px-2 py-0.5 text-xs font-medium backdrop-blur">
            {business.categories[0].name}
          </span>
        )}
        <h1 className="text-2xl font-bold">{business?.name ?? "Leave a review"}</h1>
        {placeLine && <p className="mt-0.5 text-sm text-white/80">{placeLine}</p>}
        <div className="mt-1 flex items-center gap-2 text-sm">
          <RatingWidget value={business?.average_rating ?? 0} readonly size="sm" />
          <span>{business?.average_rating ? business.average_rating.toFixed(1) : "New"}</span>
          <span className="text-white/80">({business?.review_count ?? 0} reviews)</span>
        </div>
      </div>

      <p className="mt-4 text-center text-sm text-muted">
        Your review takes &lt; 30 seconds · Helps locals discover this place
      </p>

      {step === "stars" && (
        <div className="mt-6 space-y-6">
          <div className="rounded-xl border border-border bg-surface-raised p-5 text-center shadow-sm">
            <p className="text-sm font-medium text-muted">How was your experience?</p>
            <div className="mt-3 flex justify-center">
              <RatingWidget value={rating} onChange={setRating} size="lg" />
            </div>
            {rating > 0 && (
              <div className="mt-5">
                <p className="mb-2 text-sm text-muted">What stood out? (optional)</p>
                <div className="flex flex-wrap justify-center gap-2">
                  {CHIPS.map((chip) => (
                    <button
                      key={chip}
                      type="button"
                      onClick={() => toggleChip(chip)}
                      className={`rounded-full border px-3 py-1 text-sm transition ${
                        selectedChips.includes(chip)
                          ? "border-brand-600 bg-brand-600 text-white"
                          : "border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
                      }`}
                    >
                      {chip}
                    </button>
                  ))}
                </div>
              </div>
            )}
            <button
              type="button"
              disabled={rating < 1}
              onClick={() => setStep("text")}
              className="mt-6 w-full rounded bg-brand-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
            >
              Continue →
            </button>
          </div>
        </div>
      )}

      {step === "text" && (
        <form onSubmit={submit} className="mt-6 space-y-3 rounded-xl border border-border bg-surface-raised p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-muted">Write your review</p>
            <button
              type="button"
              onClick={fillDraft}
              className="text-sm font-medium text-brand-700 hover:underline"
            >
              Generate a starter →
            </button>
          </div>
          <textarea
            required
            minLength={10}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="w-full rounded border border-border bg-surface-raised text-ink p-2 text-sm"
            rows={6}
            placeholder="Share what made your visit memorable…"
          />
          <div className="h-1 w-full overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
            <div
              className={`h-full transition-all ${body.length >= 50 ? "bg-green-500" : "bg-brand-400"}`}
              style={{ width: `${Math.min(100, (body.length / 50) * 100)}%` }}
            />
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button type="submit" className="rounded bg-brand-600 px-4 py-2 text-sm text-white">
            Submit review
          </button>
        </form>
      )}

      {step === "done" && (
        <div className="mt-6 space-y-4 text-center">
          <div className="rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-2xl text-green-600">
              ✓
            </div>
            <p className="mt-3 text-lg font-semibold">Thank you! Your review is live.</p>
            <p className="mt-1 text-sm text-muted">
              You're one of {(business?.review_count ?? 0) + 1} people who reviewed this spot.
            </p>
          </div>

          <a
            href={mapsHref}
            target="_blank"
            rel="noreferrer"
            className="block rounded-xl border border-brand-200 bg-brand-50 p-4 text-left hover:bg-brand-100"
          >
            <p className="font-medium text-brand-800">Share on Google Maps too →</p>
            <p className="mt-1 text-sm text-brand-700">Takes 10 more seconds · Helps them rank higher</p>
          </a>

          <a href="/search" className="block text-sm text-muted hover:underline">
            Review another place near you →
          </a>
        </div>
      )}

      {step !== "text" && (
        <div className="mt-6">
          <SocialProof reviews={recentReviews} />
        </div>
      )}
    </div>
  );
}

function SocialProof({ reviews }: { reviews: Review[] }) {
  if (reviews.length === 0) return null;
  return (
    <div>
      <p className="mb-3 text-sm font-medium text-muted">What others said</p>
      <ul className="space-y-3">
        {reviews.map((r) => (
          <li key={r.id} className="flex gap-3 rounded-lg border border-border bg-surface-raised p-3 shadow-sm">
            <div className="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700">
              {(r.author?.full_name || "C").charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <RatingWidget value={r.rating} readonly size="sm" />
                <span className="text-xs text-muted">{new Date(r.created_at).toLocaleDateString()}</span>
              </div>
              <p className="mt-1 line-clamp-2 text-sm text-muted">{r.body.slice(0, 100)}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
