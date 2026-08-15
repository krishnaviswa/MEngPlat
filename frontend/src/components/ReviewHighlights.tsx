import type { Review } from "@/lib/api";

interface ReviewHighlightsProps {
  reviews: Review[];
  averageRating: number;
}

/** ReviewHighlights — three stat chips (avg rating, review count, top sentiment) above the review list. */
export function ReviewHighlights({ reviews, averageRating }: ReviewHighlightsProps) {
  const sentimentCounts: Record<string, number> = {};
  for (const r of reviews) {
    const s = r.ai_analysis?.sentiment;
    if (s) sentimentCounts[s] = (sentimentCounts[s] ?? 0) + 1;
  }
  const topSentiment = Object.entries(sentimentCounts).sort((a, b) => b[1] - a[1])[0]?.[0];

  return (
    <div className="mb-4 flex flex-wrap gap-2">
      <span className="rounded-full bg-brand-50 px-3 py-1 text-sm font-medium text-brand-800">
        {averageRating.toFixed(1)}★ avg
      </span>
      <span className="rounded-full bg-brand-50 px-3 py-1 text-sm font-medium text-brand-800">
        {reviews.length} reviews
      </span>
      {topSentiment && (
        <span className="rounded-full bg-brand-50 px-3 py-1 text-sm font-medium capitalize text-brand-800">
          Mostly {topSentiment}
        </span>
      )}
    </div>
  );
}
