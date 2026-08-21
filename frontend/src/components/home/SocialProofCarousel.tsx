"use client";

import { useRef, type ReactNode } from "react";

/** Horizontal shop strip with visible scroll + prev/next (S-116). Server rail wraps this. */
export function SocialProofCarousel({ children }: { children: ReactNode }) {
  const scroller = useRef<HTMLDivElement>(null);

  function scrollByPage(direction: -1 | 1) {
    const el = scroller.current;
    if (!el) return;
    el.scrollBy({ left: direction * el.clientWidth * 0.8, behavior: "smooth" });
  }

  return (
    <div className="relative mt-6">
      <button
        type="button"
        aria-label="Previous shops"
        className="absolute left-0 top-1/2 z-10 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-border bg-surface-raised text-ink shadow-sm"
        onClick={() => scrollByPage(-1)}
      >
        <span aria-hidden="true">‹</span>
      </button>
      <div
        ref={scroller}
        className="overflow-x-auto px-4 pb-3 [-webkit-overflow-scrolling:touch]"
      >
        <div className="flex w-max snap-x snap-mandatory gap-6 pr-16">{children}</div>
      </div>
      <button
        type="button"
        aria-label="Next shops"
        className="absolute right-0 top-1/2 z-10 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-border bg-surface-raised text-ink shadow-sm"
        onClick={() => scrollByPage(1)}
      >
        <span aria-hidden="true">›</span>
      </button>
    </div>
  );
}
