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
  { name: "Riverside Diner", initial: "RD" },
  { name: "Golden Wok Kitchen", initial: "GW" },
  { name: "Chrompet Family Hospital", initial: "CF" },
  { name: "Sunrise Urgent Care", initial: "SU" },
  { name: "Blue Ridge Pharmacy", initial: "BR" },
  { name: "Nagar Medical Store", initial: "NM" },
  { name: "Fresh Fields Grocery", initial: "FF" },
  { name: "Bandra Fresh Mart", initial: "BF" },
  { name: "Cedar Street Salon", initial: "CS" },
  { name: "Glow Beauty Bar", initial: "GB" },
  { name: "Steel City Auto Works", initial: "SC" },
  { name: "Quick Fix Motors", initial: "QF" },
  { name: "Daily Grind Coffee House", initial: "DG" },
  { name: "Chai Point Corner", initial: "CP" },
  { name: "Harborview Bistro", initial: "HB" },
  { name: "Curry Leaf Kitchen", initial: "CL" },
  { name: "Metro Wellness Clinic", initial: "MW" },
  { name: "Lotus Care Hospital", initial: "LC" },
  { name: "Value Mart Pharmacy", initial: "VM" },
  { name: "Everyday Essentials Grocery", initial: "EE" },
  { name: "Silver Scissors Salon", initial: "SS" },
  { name: "Trend Cutz Studio", initial: "TC" },
  { name: "Precision Auto Care", initial: "PA" },
  { name: "Neighborhood Bike & Auto", initial: "NB" },
];

/** Slugs of the mock businesses seeded by backend/scripts/seed_social_proof.py. */
const SOCIAL_PROOF_SLUGS = [
  "copper-kettle-cafe",
  "bright-smile-dental",
  "chrompet-cycle-repair",
  "verde-salon-spa",
  "anand-grocers",
  "pixel-print-studio",
  "riverside-diner",
  "golden-wok-kitchen",
  "chrompet-family-hospital",
  "sunrise-urgent-care",
  "blue-ridge-pharmacy",
  "nagar-medical-store",
  "fresh-fields-grocery",
  "bandra-fresh-mart",
  "cedar-street-salon",
  "glow-beauty-bar",
  "steel-city-auto-works",
  "quick-fix-motors",
  "daily-grind-coffee-house",
  "chai-point-corner",
  "harborview-bistro",
  "curry-leaf-kitchen",
  "metro-wellness-clinic",
  "lotus-care-hospital",
  "value-mart-pharmacy",
  "everyday-essentials-grocery",
  "silver-scissors-salon",
  "trend-cutz-studio",
  "precision-auto-care",
  "neighborhood-bike-auto",
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
