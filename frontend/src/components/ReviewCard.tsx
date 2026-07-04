import type { Review } from "@/lib/api";
import { RatingWidget } from "./RatingWidget";

interface ReviewCardProps {
  review: Review;
  onLike?: (id: string) => void;
  onReport?: (id: string) => void;
  showActions?: boolean;
}

/** ReviewCard — single review with AI sentiment badge and optional actions. */
export function ReviewCard({ review, onLike, onReport, showActions = true }: ReviewCardProps) {
  const sentiment = review.ai_analysis?.sentiment;
  const sentimentColor =
    sentiment === "positive" ? "bg-green-100 text-green-800" :
    sentiment === "negative" ? "bg-red-100 text-red-800" :
    "bg-gray-100 text-gray-800";

  return (
    <article className="rounded-xl border bg-white p-4 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="font-medium">{review.author?.full_name || "Customer"}</p>
          <RatingWidget value={review.rating} readonly size="sm" />
        </div>
        {sentiment && (
          <span className={`rounded-full px-2 py-0.5 text-xs capitalize ${sentimentColor}`}>
            AI: {sentiment}
          </span>
        )}
      </div>
      {review.title && <h4 className="mt-2 font-semibold">{review.title}</h4>}
      <p className="mt-1 text-gray-700">{review.body}</p>
      {review.ai_analysis?.summary && (
        <p className="mt-2 rounded bg-brand-50 p-2 text-sm text-brand-900">
          <span className="font-medium">AI summary (suggestion):</span> {review.ai_analysis.summary}
        </p>
      )}
      {review.photo_urls && review.photo_urls.length > 0 && (
        <div className="mt-3 flex gap-2">
          {review.photo_urls.map((url) => (
            <img key={url} src={url} alt="" className="h-16 w-16 rounded object-cover" />
          ))}
        </div>
      )}
      {showActions && (
        <div className="mt-3 flex gap-3 text-sm text-gray-500">
          <button onClick={() => onLike?.(review.id)} className="hover:text-brand-600">
            👍 {review.like_count}
          </button>
          <button onClick={() => onReport?.(review.id)} className="hover:text-red-600">
            Report
          </button>
        </div>
      )}
    </article>
  );
}
