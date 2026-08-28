import type { Business } from "@/lib/api";
import { RatingWidget } from "./ui/RatingWidget";

interface BusinessCardProps {
  business: Business;
  href?: string;
}

/** BusinessCard — Google-Maps-style listing card with storefront photo, address, and ratings. */
export function BusinessCard({ business, href }: BusinessCardProps) {
  const link = href || `/businesses/${business.slug}`;
  const image = business.storefront_url || business.logo_url;
  const placeLine = [business.address, business.city].filter(Boolean).join(", ");
  const category = business.categories?.[0]?.name || "Local business";

  return (
    <a
      href={link}
      className="group block overflow-hidden rounded-xl border border-border bg-surface-raised shadow-sm transition hover:shadow-md"
    >
      <div className="relative aspect-[16/10] bg-brand-50">
        {image ? (
          <img
            src={image}
            alt=""
            className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.02]"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-4xl">🏪</div>
        )}
        <span className="absolute left-3 top-3 rounded bg-surface-raised/95 px-2 py-0.5 text-xs font-medium text-muted shadow-sm">
          {category}
        </span>
        {business.is_featured && (
          <span className="absolute right-3 top-3 rounded bg-brand-700 px-2 py-0.5 text-xs font-medium text-white shadow-sm">
            Featured
          </span>
        )}
      </div>
      <div className="p-4">
        <h3 className="text-lg font-semibold text-ink group-hover:text-brand-700">{business.name}</h3>
        {placeLine && <p className="mt-1 text-sm text-muted">{placeLine}</p>}
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <RatingWidget value={business.average_rating} readonly size="sm" />
          <span className="text-sm font-medium text-muted">
            {business.average_rating ? business.average_rating.toFixed(1) : "New"}
          </span>
          <span className="text-xs text-muted">({business.review_count} reviews)</span>
        </div>
      </div>
    </a>
  );
}
