export interface SocialProofEntry {
  name: string;
  /** 1–2 char fallback badge rendered when no logo asset exists yet (placeholder era). */
  initial: string;
  /** Optional future logo asset path; undefined for all placeholder entries in this slice. */
  logoUrl?: string;
}

/** Placeholder roster — swap for real client names/logos post-launch. */
export const SOCIAL_PROOF_ENTRIES: SocialProofEntry[] = [
  { name: "Copper Kettle Cafe", initial: "CK" },
  { name: "Bright Smile Dental", initial: "BS" },
  { name: "Chrompet Cycle Repair", initial: "CC" },
  { name: "Verde Salon & Spa", initial: "VS" },
  { name: "Anand Grocers", initial: "AG" },
  { name: "Pixel Print Studio", initial: "PP" },
];

/** SocialProofRail — static "businesses using MerchantHub" logo/name strip. No props, no fetch. */
export function SocialProofRail() {
  return (
    <section className="mh-section-reveal border-b border-border/80 bg-surface-raised/40">
      <div className="mx-auto max-w-6xl px-4 py-10">
        <p className="text-center font-display text-xs font-semibold uppercase tracking-[0.2em] text-muted">
          Businesses using MerchantHub
        </p>
        <div className="mt-6 flex flex-wrap items-center justify-center gap-x-10 gap-y-6 grayscale">
          {SOCIAL_PROOF_ENTRIES.map((entry) => (
            <div key={entry.name} className="flex items-center gap-2 opacity-60">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-200 text-xs font-semibold text-slate-600 dark:bg-slate-700 dark:text-slate-300">
                {entry.initial}
              </span>
              <span className="font-display text-sm font-medium text-ink">{entry.name}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
