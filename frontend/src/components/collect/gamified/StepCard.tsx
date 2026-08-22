"use client";

import type { ReactNode } from "react";

/** Full-screen animated shell for one gamified-flow question. `screenKey` forces a remount (and re-triggers the CSS entrance animation) on every step change. */
export function StepCard({ screenKey, children }: { screenKey: string; children: ReactNode }) {
  return (
    <div
      key={screenKey}
      className="animate-pop-in rounded-xl border border-border bg-surface-raised p-5 text-center shadow-sm"
    >
      {children}
    </div>
  );
}
