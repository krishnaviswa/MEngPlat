import type { Business } from "@/lib/api";
import { RatingWidget } from "./RatingWidget";

interface BusinessCardProps {
  business: Business;
  href?: string;
}

/** BusinessCard — compact listing for search/home grids. Props: business, optional href. */
export function BusinessCard({ business, href }: BusinessCardProps) {
  const link = href || `/businesses/${business.slug}`;
  return (
    <a
      href={link}
      className="block rounded-xl border bg-white p-4 shadow-sm transition hover:shadow-md"
    >
      <div className="flex gap-4">
        <div className="flex h-16 w-16 items-center justify-center rounded-lg bg-brand-50 text-2xl">
          {business.logo_url ? (
            <img src={business.logo_url} alt="" className="h-full w-full rounded-lg object-cover" />
          ) : (
            "🏪"
          )}
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-gray-900">{business.name}</h3>
          <p className="text-sm text-gray-500">
            {business.city} · {business.categories?.[0]?.name || "Local business"}
          </p>
          <div className="mt-2 flex items-center gap-2">
            <RatingWidget value={business.average_rating} readonly size="sm" />
            <span className="text-xs text-gray-500">({business.review_count} reviews)</span>
          </div>
        </div>
      </div>
    </a>
  );
}
