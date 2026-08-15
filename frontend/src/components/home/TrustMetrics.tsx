import type { PublicPlatformStats } from "@/lib/api";

interface TrustMetricsProps {
  stats: PublicPlatformStats;
}

/** TrustMetrics — editorial live platform counts below the hero (not overlaid). */
export function TrustMetrics({ stats }: TrustMetricsProps) {
  const items = [
    { label: "Approved businesses", value: stats.total_businesses },
    { label: "Active reviews", value: stats.total_reviews },
    { label: "Categories", value: stats.total_categories },
    { label: "Cities covered", value: stats.total_cities },
  ];

  return (
    <section className="mh-section-reveal border-y border-border/80 bg-surface-raised/70 backdrop-blur-sm">
      <div className="mx-auto grid max-w-6xl grid-cols-2 gap-8 px-4 py-10 md:grid-cols-4">
        {items.map((item) => (
          <div key={item.label} className="text-center md:text-left">
            <p className="font-display text-3xl font-semibold tracking-tight text-brand-800 dark:text-brand-300 md:text-4xl">
              {(item.value ?? 0).toLocaleString()}
            </p>
            <p className="mt-1 text-sm text-muted">{item.label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
