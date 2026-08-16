import type { ExternalReview } from "@/lib/api";

interface ExternalReviewsProps {
  reviews: ExternalReview[];
}

/**
 * ExternalReviews — "Also reviewed on Google" section (S-048 AC10, AC11, AC15).
 * Plain Server Component, no client interactivity needed for a read-only list.
 * Returns null when empty (no placeholder box), same graceful-degrade
 * convention as other optional profile sections. Visually distinct container
 * from ReviewsList/ReviewCard on purpose -- external reviews have no
 * author_id, reply, or like affordance.
 */
export function ExternalReviews({ reviews }: ExternalReviewsProps) {
  if (reviews.length === 0) return null;

  return (
    <section className="mt-8 rounded-xl border border-brand-200 bg-brand-50/40 p-6 dark:border-brand-800/50 dark:bg-brand-900/10">
      <h2 className="text-xl font-semibold">Also reviewed on Google</h2>
      <p className="mt-1 text-sm text-muted">
        Showing up to 5 most-relevant Google reviews, pulled in by the business owner -- not a full review history.
      </p>
      <ul className="mt-4 space-y-4">
        {reviews.map((review) => (
          <li key={review.id} className="rounded-lg border border-border bg-surface-raised p-4">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                {review.author_photo_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={review.author_photo_url} alt="" className="h-8 w-8 rounded-full object-cover" />
                ) : (
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-xs font-semibold text-brand-700 dark:bg-brand-900/40 dark:text-brand-300">
                    {review.author_name.charAt(0).toUpperCase()}
                  </span>
                )}
                <span className="text-sm font-medium text-ink">{review.author_name}</span>
              </div>
              <span aria-label={`${review.rating} out of 5 stars`} className="text-sm text-yellow-500">
                {"★".repeat(review.rating)}
                <span className="text-gray-300 dark:text-gray-600">{"★".repeat(5 - review.rating)}</span>
              </span>
            </div>
            <p className="mt-2 text-sm text-muted">
              {review.body ?? <em>No written review</em>}
            </p>
            {review.source_url && (
              <a
                href={review.source_url}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-2 inline-block text-xs text-brand-600 hover:underline"
              >
                View on Google
              </a>
            )}
          </li>
        ))}
      </ul>
    </section>
  );
}
