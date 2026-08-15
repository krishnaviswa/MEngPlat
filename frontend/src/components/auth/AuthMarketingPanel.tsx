import type { PublicPlatformStats } from "@/lib/api";

interface AuthMarketingPanelProps {
  stats?: PublicPlatformStats | null;
}

const FEATURES = [
  {
    title: "Real reviews, real visits",
    body: "Every review ties back to a customer — no anonymous noise, no pay-to-hide reviews.",
  },
  {
    title: "AI-suggested insights",
    body: "Sentiment and summaries are always labeled as suggestions, never presented as a final verdict.",
  },
  {
    title: "Built for local shops",
    body: "Cafés, salons, clinics, repair shops — claim a listing and reply directly to customers.",
  },
];

/** AuthMarketingPanel — brand story shown beside the login/register form so auth pages aren't a bare card on white. */
export function AuthMarketingPanel({ stats }: AuthMarketingPanelProps) {
  const items = stats
    ? [
        { label: "Approved businesses", value: stats.total_businesses },
        { label: "Active reviews", value: stats.total_reviews },
        { label: "Cities covered", value: stats.total_cities },
      ]
    : [];

  return (
    <div className="mx-auto max-w-lg lg:mx-0">
      <p className="font-display text-sm font-semibold uppercase tracking-[0.2em] text-brand-700">
        MerchantHub
      </p>
      <h1 className="mt-4 font-display text-3xl font-semibold leading-tight tracking-tight text-slate-900 sm:text-4xl">
        The trusted home for local business reviews
      </h1>
      <p className="mt-4 text-lg text-slate-600">
        Find neighborhood shops with photos, ratings, and AI-suggested insights — never presented
        as definitive judgments.
      </p>

      <ul className="mt-8 space-y-5">
        {FEATURES.map((f) => (
          <li key={f.title} className="flex gap-3">
            <span className="mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-brand-100 text-brand-700">
              ✓
            </span>
            <div>
              <p className="font-medium text-slate-900">{f.title}</p>
              <p className="mt-0.5 text-sm text-slate-600">{f.body}</p>
            </div>
          </li>
        ))}
      </ul>

      {items.length > 0 && (
        <div className="mt-10 grid grid-cols-3 gap-4 border-t border-slate-200 pt-6">
          {items.map((item) => (
            <div key={item.label}>
              <p className="font-display text-2xl font-semibold tracking-tight text-brand-800">
                {(item.value ?? 0).toLocaleString()}
              </p>
              <p className="mt-1 text-xs text-slate-500">{item.label}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
