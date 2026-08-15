import type { Business, Review } from "@/lib/api";
import { RatingWidget } from "@/components/ui/RatingWidget";

export interface ReviewVoiceItem {
  business: Business;
  review: Review;
}

interface ReviewVoicesProps {
  items: ReviewVoiceItem[];
}

/** ReviewVoices — real neighborhood reviews with AI summary framed as a suggestion. */
export function ReviewVoices({ items }: ReviewVoicesProps) {
  if (items.length === 0) return null;

  return (
    <section className="mh-section-reveal mx-auto max-w-6xl px-4 py-16">
      <div className="max-w-2xl">
        <h2 className="font-display text-3xl font-semibold tracking-tight text-ink">
          Voices from the neighborhood
        </h2>
        <p className="mt-2 text-muted">
          Recent reviews from real listings — AI notes are suggestions, not definitive judgments.
        </p>
      </div>
      <ul className="mt-10 grid gap-10 lg:grid-cols-3">
        {items.map(({ business, review }) => (
          <li key={review.id} className="flex flex-col border-t border-border pt-6">
            <div className="flex items-center gap-2">
              <RatingWidget value={review.rating} readonly size="sm" />
              <span className="text-sm font-medium text-muted">{review.rating.toFixed(1)}</span>
            </div>
            {review.title && (
              <p className="mt-3 font-display text-lg font-semibold text-ink">{review.title}</p>
            )}
            <p className="mt-2 line-clamp-4 text-muted">{review.body}</p>
            {review.ai_analysis?.summary && (
              <p className="mt-4 border-l-2 border-brand-400 pl-3 text-sm text-muted">
                <span className="font-medium text-brand-800 dark:text-brand-300">In a nutshell: </span>
                {review.ai_analysis.summary}
              </p>
            )}
            <a
              href={`/businesses/${business.slug}`}
              className="mt-auto pt-5 text-sm font-medium text-brand-700 hover:underline"
            >
              {business.name}
              {business.city ? ` · ${business.city}` : ""}
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
