"use client";

import { RatingWidget } from "@/components/ui/RatingWidget";

/** Tap-only star step. Every rating (1-5) advances identically — no low-star intercept (S-040). */
export function StarStep({ rating, onSelect }: { rating: number; onSelect: (value: number) => void }) {
  return (
    <div>
      <p className="animate-bounce-in text-sm font-medium text-muted">How was your experience?</p>
      <div className="mt-3 flex justify-center">
        <RatingWidget value={rating} onChange={onSelect} size="lg" />
      </div>
      <p className="mt-4 text-xs text-muted">Tap a star to continue</p>
    </div>
  );
}
