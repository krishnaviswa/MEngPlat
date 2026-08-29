"use client";

import { use, useEffect, useState } from "react";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { generateDraft } from "@/components/collect/DraftEngine";
import { CHIPS } from "@/components/collect/constants";
import { GamifiedCollectFlow } from "@/components/collect/gamified/GamifiedCollectFlow";
import { CelebrationStep } from "@/components/collect/gamified/CelebrationStep";
import { InlineAuthStep } from "@/components/collect/InlineAuthStep";
import { isGamifiedReviewEnabled } from "@/lib/featureFlags";
import { API_URL, auth, businesses, reviews } from "@/lib/api";
import type { Business, Review } from "@/lib/api";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function resolveUrl(url: string): string {
  return url.startsWith("http") ? url : `${API_URL}${url}`;
}

function isNotFound(err: unknown): boolean {
  return typeof err === "object" && err !== null && "status" in err && (err as { status: number }).status === 404;
}

/** Public collect URL may be a listing slug or a business UUID. */
async function resolveBusiness(param: string): Promise<Business> {
  if (UUID_RE.test(param)) {
    return businesses.getById(param);
  }
  try {
    return await businesses.get(param);
  } catch (err) {
    if (isNotFound(err)) {
      return businesses.getById(param);
    }
    throw err;
  }
}

/** Public review-collection hub. All star ratings continue equally — no low-star intercept. */
export default function CollectReviewPage({ params }: { params: Promise<{ businessId: string }> }) {
  const { businessId } = use(params);
  const [step, setStep] = useState<"stars" | "text" | "done">("stars");
  const [rating, setRating] = useState(0);
  const [selectedChips, setSelectedChips] = useState<string[]>([]);
  const [body, setBody] = useState("");
  const [error, setError] = useState("");
  const [business, setBusiness] = useState<Business | null>(null);
  const [recentReviews, setRecentReviews] = useState<Review[]>([]);
  const [loadFailed, setLoadFailed] = useState(false);
  const [submitted, setSubmitted] = useState<Review | null>(null);
  const [celebrated, setCelebrated] = useState(false);
  // S-121: Submit while unauthenticated swaps the current step's content for
  // InlineAuthStep in place, instead of navigating to /login (see ADR-018).
  const [authPending, setAuthPending] = useState(false);
  const gamified = isGamifiedReviewEnabled();

  useEffect(() => {
    resolveBusiness(businessId)
      .then((match) => {
        setBusiness(match);
        setLoadFailed(false);
        return reviews.list(match.id);
      })
      .then((list) => setRecentReviews(list.slice(0, 2)))
      .catch(() => {
        setBusiness(null);
        setLoadFailed(true);
      });
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

  /** Actually posts the review — called once already authenticated, either
   * directly from `submit()` or right after `handleAuthenticated()` fires. */
  async function createReview() {
    setError("");
    try {
      const created = await reviews.create({ business_id: business!.id, rating, body });
      setSubmitted(created);
      setStep("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not submit review");
    }
  }

  async function submit() {
    setError("");
    try {
      await auth.me();
    } catch {
      // S-121: show the inline sign-in step in place, no navigation away —
      // rating/chips/body stay exactly as composed (ADR-018).
      setAuthPending(true);
      return;
    }
    await createReview();
  }

  /** Fired by InlineAuthStep once sign-in succeeds — auto-submits the review
   * already held in state, no re-entry (S-121 AC6). */
  function handleAuthenticated() {
    setAuthPending(false);
    void createReview();
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
        <h1 className="text-2xl font-bold">
          {business?.name ?? (loadFailed ? "Shop not found" : "Leave a review")}
        </h1>
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

      {gamified && step === "stars" && (
        <GamifiedCollectFlow
          rating={rating}
          setRating={setRating}
          selectedChips={selectedChips}
          toggleChip={toggleChip}
          body={body}
          setBody={setBody}
          fillDraft={fillDraft}
          error={error}
          onSubmit={submit}
          authPending={authPending}
          onAuthenticated={handleAuthenticated}
        />
      )}

      {!gamified && step === "stars" && (
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

      {!gamified && step === "text" && authPending && (
        <div className="mt-6 space-y-3 rounded-xl border border-border bg-surface-raised p-5 shadow-sm">
          <InlineAuthStep onAuthenticated={handleAuthenticated} />
        </div>
      )}

      {!gamified && step === "text" && !authPending && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            void submit();
          }}
          className="mt-6 space-y-3 rounded-xl border border-border bg-surface-raised p-5 shadow-sm"
        >
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

      {step === "done" && gamified && !celebrated && (
        <CelebrationStep onContinue={() => setCelebrated(true)} />
      )}

      {step === "done" && (!gamified || celebrated) && (
        <div className="mt-6 space-y-4 text-center">
          <div className="rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-2xl text-green-600">
              ✓
            </div>
            {submitted?.status === "reported" ? (
              <>
                <p className="mt-3 text-lg font-semibold">Thanks — we received your review.</p>
                <p className="mt-1 text-sm text-muted">
                  It is held for admin review because the text may not meet our content rules. It is not
                  live on the listing yet.
                </p>
              </>
            ) : (
              <>
                <p className="mt-3 text-lg font-semibold">Thank you! Your review is live.</p>
                <p className="mt-1 text-sm text-muted">
                  You&apos;re one of {(business?.review_count ?? 0) + 1} people who reviewed this spot. No
                  merchant or admin approval is required.
                </p>
              </>
            )}
            {submitted && (
              <div className="mt-4 text-left">
                <RatingWidget value={submitted.rating} readonly size="sm" />
                {submitted.body ? (
                  <p className="mt-2 text-sm text-ink">{submitted.body}</p>
                ) : null}
              </div>
            )}
            {business?.slug && submitted?.status !== "reported" && (
              <a
                href={`/businesses/${business.slug}`}
                className="mt-4 inline-block text-sm font-medium text-brand-700 hover:underline"
              >
                See it on the listing →
              </a>
            )}
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

      {step !== "text" && !(gamified && step === "done" && !celebrated) && (
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
