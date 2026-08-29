"use client";

import { use, useEffect, useState } from "react";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { generateDraft } from "@/components/collect/DraftEngine";
import { CHIPS } from "@/components/collect/constants";
import { GamifiedCollectFlow } from "@/components/collect/gamified/GamifiedCollectFlow";
import { CelebrationStep } from "@/components/collect/gamified/CelebrationStep";
import { collectToken } from "@/lib/api";
import type { CollectTokenContext } from "@/lib/api";

type Phase = "loading" | "invalid" | "active" | "done";

/**
 * S-123 — login-free review collection for the partner channel.
 *
 * The single-use token minted by a billing/POS partner for one transaction is
 * the only thing that unlocks this page. No `auth.me()`, no `/login` redirect —
 * that is deliberate and lives *only* here (organic `/collect/{businessId}`
 * keeps its login gate). Always the S-119 gamified flow.
 */
export default function TokenCollectPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
  const [phase, setPhase] = useState<Phase>("loading");
  const [ctx, setCtx] = useState<CollectTokenContext | null>(null);
  const [invalidReason, setInvalidReason] = useState("");
  const [rating, setRating] = useState(0);
  const [selectedChips, setSelectedChips] = useState<string[]>([]);
  const [body, setBody] = useState("");
  const [error, setError] = useState("");
  const [heldForModeration, setHeldForModeration] = useState(false);
  const [celebrated, setCelebrated] = useState(false);

  useEffect(() => {
    collectToken
      .context(token)
      .then((c) => {
        setCtx(c);
        if (c.status === "submitted") {
          setInvalidReason("This review link has already been used. Thanks for your feedback!");
          setPhase("invalid");
        } else if (c.status === "expired") {
          setInvalidReason("This review link has expired. Ask the shop for a fresh one.");
          setPhase("invalid");
        } else {
          setPhase("active");
        }
      })
      .catch(() => {
        setInvalidReason("This review link is not valid.");
        setPhase("invalid");
      });
  }, [token]);

  function toggleChip(chip: string) {
    setSelectedChips((prev) => (prev.includes(chip) ? prev.filter((c) => c !== chip) : [...prev, chip]));
  }

  function fillDraft() {
    setBody(
      generateDraft({
        rating,
        chips: selectedChips,
        businessName: ctx?.business.name ?? "this place",
        city: ctx?.business.city ?? undefined,
      }),
    );
  }

  async function submit() {
    setError("");
    try {
      const result = await collectToken.submit(token, { rating, body });
      setHeldForModeration(result.status === "reported");
      setPhase("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not submit your review");
    }
  }

  const business = ctx?.business;

  return (
    <div className="mx-auto max-w-lg px-4 pb-16">
      <div className="relative -mx-4 flex h-40 flex-col justify-end bg-gradient-to-br from-brand-600 to-brand-800 px-4 pb-4 text-white sm:mx-0 sm:h-48 sm:rounded-b-xl">
        <span className="mb-1 w-fit rounded-full bg-white/20 px-2 py-0.5 text-xs font-medium backdrop-blur">
          ✓ Verified purchase
        </span>
        <h1 className="text-2xl font-bold">{business?.name ?? "Leave a review"}</h1>
        {business?.city && <p className="mt-0.5 text-sm text-white/80">{business.city}</p>}
      </div>

      <p className="mt-4 text-center text-sm text-muted">
        You&apos;re reviewing a real purchase · Takes &lt; 30 seconds · No account needed
      </p>

      {phase === "loading" && <p className="mt-10 text-center text-sm text-muted">Loading…</p>}

      {phase === "invalid" && (
        <div className="mt-6 rounded-xl border border-border bg-surface-raised p-6 text-center shadow-sm">
          <p className="text-lg font-semibold">Review link unavailable</p>
          <p className="mt-1 text-sm text-muted">{invalidReason}</p>
          <a href="/search" className="mt-4 inline-block text-sm font-medium text-brand-700 hover:underline">
            Find a business to review →
          </a>
        </div>
      )}

      {phase === "active" && (
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
          authPending={false}
          onAuthenticated={() => undefined}
        />
      )}

      {phase === "done" && !celebrated && <CelebrationStep onContinue={() => setCelebrated(true)} />}

      {phase === "done" && celebrated && (
        <div className="mt-6 space-y-4 text-center">
          <div className="rounded-xl border border-border bg-surface-raised p-6 shadow-sm">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-2xl text-green-600">
              ✓
            </div>
            {heldForModeration ? (
              <>
                <p className="mt-3 text-lg font-semibold">Thanks — we received your review.</p>
                <p className="mt-1 text-sm text-muted">
                  It is held for a quick check because the text may not meet our content rules. It is
                  not live on the listing yet.
                </p>
              </>
            ) : (
              <>
                <p className="mt-3 text-lg font-semibold">Thank you! Your verified review is live.</p>
                <p className="mt-1 text-sm text-muted">
                  It is marked a verified purchase. No merchant or admin approval is required.
                </p>
              </>
            )}
            <div className="mt-4 flex justify-center">
              <RatingWidget value={rating} readonly size="sm" />
            </div>
            {business?.slug && !heldForModeration && (
              <a
                href={`/businesses/${business.slug}`}
                className="mt-4 inline-block text-sm font-medium text-brand-700 hover:underline"
              >
                See it on the listing →
              </a>
            )}
          </div>
          <a href="/search" className="block text-sm text-muted hover:underline">
            Review another place near you →
          </a>
        </div>
      )}
    </div>
  );
}
