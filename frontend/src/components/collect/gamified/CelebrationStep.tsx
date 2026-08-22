"use client";

import { useEffect } from "react";

/** Brief celebratory acknowledgment after a successful submit, then hands off to the existing done screen. */
export function CelebrationStep({ onContinue }: { onContinue: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onContinue, 1400);
    return () => clearTimeout(timer);
  }, [onContinue]);

  return (
    <div className="mt-6 animate-pop-in rounded-xl border border-border bg-surface-raised p-8 text-center shadow-sm">
      <div className="mx-auto flex h-16 w-16 animate-celebrate-pulse items-center justify-center rounded-full bg-green-100 text-3xl text-green-600">
        ✓
      </div>
      <p className="mt-4 text-lg font-semibold">Review submitted!</p>
      <p className="mt-1 text-sm text-muted">Thanks for taking the time — nice job.</p>
      <button type="button" onClick={onContinue} className="mt-4 text-sm font-medium text-brand-700 hover:underline">
        Continue →
      </button>
    </div>
  );
}
