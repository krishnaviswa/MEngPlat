import { businesses, type Business } from "@/lib/api";

export interface SocialProofEntry {
  name: string;
  /** 1–2 char fallback badge rendered when no photo is available. */
  initial: string;
  logoUrl?: string;
  storefrontUrl?: string;
}

/** Fallback roster, used only if the seeded businesses below can't be loaded. */
export const SOCIAL_PROOF_ENTRIES: SocialProofEntry[] = [
  { name: "Copper Kettle Cafe", initial: "CK" },
  { name: "Bright Smile Dental", initial: "BS" },
  { name: "Chrompet Cycle Repair", initial: "CC" },
  { name: "Verde Salon & Spa", initial: "VS" },
  { name: "Anand Grocers", initial: "AG" },
  { name: "Pixel Print Studio", initial: "PP" },
];

/** Slugs of the mock businesses seeded by backend/scripts/seed_social_proof.py. */
const SOCIAL_PROOF_SLUGS = [
  "copper-kettle-cafe",
  "bright-smile-dental",
  "chrompet-cycle-repair",
  "verde-salon-spa",
  "anand-grocers",
  "pixel-print-studio",
];

function initialsFor(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0]?.toUpperCase() ?? "")
    .join("");
}

/**
 * Keeps only businesses matching the curated slugs, in curated order — a defensive filter
 * so a backend that doesn't (yet) honor the `slugs` query param can't dump its whole
 * (unfiltered, up-to-50-row) business list into this rail.
 */
function toEntries(list: Business[]): SocialProofEntry[] {
  const bySlug = new Map(list.map((b) => [b.slug, b]));
  return SOCIAL_PROOF_SLUGS.map((slug) => bySlug.get(slug))
    .filter((b): b is Business => Boolean(b))
    .map((b) => ({
      name: b.name,
      initial: initialsFor(b.name),
      logoUrl: b.logo_url ?? undefined,
      storefrontUrl: b.storefront_url ?? undefined,
    }));
}

async function loadSocialProofEntries(): Promise<SocialProofEntry[]> {
  try {
    const seeded = await businesses.list({ slugs: SOCIAL_PROOF_SLUGS.join(",") });
    const matched = toEntries(seeded);
    if (matched.length > 0) return matched;
  } catch (error) {
    console.error("[SocialProofRail] failed to load seeded businesses:", error);
  }
  return SOCIAL_PROOF_ENTRIES;
}

/** SocialProofRail — "businesses using MerchantHub" card carousel. Fetches seeded mock
 * merchants for real shop photos, falling back to initials cards if that fails. Shows
 * ~3-4 cards on screen at a time; the rest scroll into view horizontally. */
export async function SocialProofRail() {
  const entries = await loadSocialProofEntries();

  return (
    <section className="mh-section-reveal border-b border-border/80 bg-surface-raised/40">
      <div className="mx-auto max-w-6xl px-4 py-10">
        <p className="text-center font-display text-xs font-semibold uppercase tracking-[0.2em] text-muted">
          Businesses using MerchantHub
        </p>
        <div className="mt-6 -mx-4 overflow-x-auto px-4 pb-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <div className="flex w-max snap-x snap-mandatory gap-6">
            {entries.map((entry) => {
              const image = entry.storefrontUrl || entry.logoUrl;
              return (
                <div
                  key={entry.name}
                  className="w-64 shrink-0 snap-start overflow-hidden rounded-xl border border-border/80 bg-surface-raised shadow-sm"
                >
                  <div className="relative aspect-[4/3] bg-brand-50">
                    {image ? (
                      <img src={image} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-2xl font-semibold text-brand-700">
                        {entry.initial}
                      </div>
                    )}
                  </div>
                  <p className="truncate p-3 font-display text-sm font-medium text-ink">{entry.name}</p>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
