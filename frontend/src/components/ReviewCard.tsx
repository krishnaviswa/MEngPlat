"use client";

import { useState } from "react";
import { RatingWidget } from "./ui/RatingWidget";
import { Textarea } from "./ui/Textarea";
import { PhotoGallery } from "./PhotoGallery";
import { API_URL } from "@/lib/api";
import type { Review } from "@/lib/api";

const TRUNCATE_THRESHOLD = 280;

interface ReviewCardProps {
  review: Review;
  onLike?: (id: string) => void;
  onReport?: (id: string, reason: string) => void;
  showActions?: boolean;
  canReply?: boolean;
  onReply?: (id: string, body: string) => void;
  /** Admin-only: render review.business as a link to its admin drill-down. */
  showBusinessLink?: boolean;
  /** Internal-audience views (admin/merchant) only — hidden from anonymous customer-facing pages. */
  showSentimentBadge?: boolean;
}

function resolveUrl(url: string): string {
  return url.startsWith("http") ? url : `${API_URL}${url}`;
}

/** ReviewCard — single review with AI sentiment badge, optional actions, and merchant reply. */
export function ReviewCard({
  review,
  onLike,
  onReport,
  showActions = true,
  canReply = false,
  onReply,
  showBusinessLink = false,
  showSentimentBadge = false,
}: ReviewCardProps) {
  const [reporting, setReporting] = useState(false);
  const [reportReason, setReportReason] = useState("");
  const [replying, setReplying] = useState(false);
  const [replyBody, setReplyBody] = useState("");
  const [submittingReply, setSubmittingReply] = useState(false);
  const [expanded, setExpanded] = useState(false);

  const isLong = review.body.length > TRUNCATE_THRESHOLD;

  const sentiment = review.ai_analysis?.sentiment;
  const sentimentColor =
    sentiment === "positive" ? "bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300" :
    sentiment === "negative" ? "bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300" :
    "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200";

  function submitReport(e: React.FormEvent) {
    e.preventDefault();
    onReport?.(review.id, reportReason);
    setReporting(false);
    setReportReason("");
  }

  async function submitReply(e: React.FormEvent) {
    e.preventDefault();
    if (!onReply) return;
    setSubmittingReply(true);
    try {
      await onReply(review.id, replyBody);
      setReplying(false);
      setReplyBody("");
    } finally {
      setSubmittingReply(false);
    }
  }

  return (
    <article className="rounded-xl border border-border bg-surface-raised p-4 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          {showBusinessLink && review.business && (
            <a
              href={`/admin/businesses/${review.business.id}`}
              className="text-sm font-medium text-brand-600 hover:underline"
            >
              {review.business.name}
            </a>
          )}
          <p className="font-medium">{review.author?.full_name || "Customer"}</p>
          <RatingWidget value={review.rating} readonly size="sm" />
        </div>
        {showSentimentBadge && sentiment && (
          <span className={`rounded-full px-2 py-0.5 text-xs capitalize ${sentimentColor}`}>
            AI: {sentiment}
          </span>
        )}
      </div>
      {review.title && <h4 className="mt-2 font-semibold">{review.title}</h4>}
      <p className={`mt-1 text-muted ${!expanded && isLong ? "line-clamp-3" : ""}`}>{review.body}</p>
      {isLong && (
        <button
          type="button"
          onClick={() => setExpanded((e) => !e)}
          className="mt-1 text-sm text-brand-600 hover:text-brand-700"
        >
          {expanded ? "Read less" : "Read more"}
        </button>
      )}
      {review.ai_analysis?.summary && (
        <p className="mt-2 rounded bg-brand-50 p-2 text-sm text-brand-900 dark:bg-brand-900/20 dark:text-brand-100">
          <span className="font-medium">Quick take:</span> {review.ai_analysis.summary}
        </p>
      )}
      {review.photo_urls && review.photo_urls.length > 0 && (
        <div className="mt-3">
          <PhotoGallery
            photos={review.photo_urls.map(resolveUrl)}
            altPrefix={`${review.author?.full_name ?? "Customer"} photo`}
            gridClassName="flex gap-2"
            thumbClassName="h-16 w-16"
          />
        </div>
      )}
      {showActions && (
        <div className="mt-3 flex gap-3 text-sm text-muted">
          <button onClick={() => onLike?.(review.id)} className="hover:text-brand-600">
            👍 {review.like_count}
          </button>
          {!reporting && (
            <button onClick={() => setReporting(true)} className="hover:text-red-600">
              Report
            </button>
          )}
        </div>
      )}
      {reporting && (
        <form onSubmit={submitReport} className="mt-3 space-y-2 rounded border border-red-100 bg-red-50 p-3 dark:border-red-900/40 dark:bg-red-900/20">
          <Textarea
            required
            minLength={10}
            value={reportReason}
            onChange={(e) => setReportReason(e.target.value)}
            placeholder="Why are you reporting this review? (min 10 characters)"
            rows={2}
          />
          <div className="flex gap-2">
            <button type="submit" className="rounded bg-red-600 px-3 py-1 text-sm text-white hover:bg-red-700">
              Submit report
            </button>
            <button
              type="button"
              onClick={() => {
                setReporting(false);
                setReportReason("");
              }}
              className="rounded border border-border px-3 py-1 text-sm hover:bg-surface"
            >
              Cancel
            </button>
          </div>
        </form>
      )}
      {review.reply && (
        <div className="mt-3 rounded border-l-2 border-brand-300 bg-surface p-3">
          <p className="text-xs font-medium text-muted">Response from the business</p>
          <p className="mt-1 text-sm text-muted">{review.reply.body}</p>
        </div>
      )}
      {canReply && !review.reply && !replying && (
        <button
          onClick={() => setReplying(true)}
          className="mt-3 text-sm text-brand-600 hover:text-brand-700"
        >
          Reply as business
        </button>
      )}
      {canReply && !review.reply && replying && (
        <form onSubmit={submitReply} className="mt-3 space-y-2 rounded border border-border p-3">
          <Textarea
            required
            minLength={5}
            value={replyBody}
            onChange={(e) => setReplyBody(e.target.value)}
            placeholder="Write a response to this review"
            rows={2}
          />
          <p className="text-xs text-muted">AI draft is a suggestion — edit before sending. It is not posted automatically.</p>
          <div className="flex gap-2">
            {review.ai_analysis?.suggested_response ? (
              <button
                type="button"
                onClick={() => setReplyBody(review.ai_analysis!.suggested_response!)}
                className="rounded border border-brand-300 px-3 py-1 text-sm text-brand-700 hover:bg-brand-50"
              >
                Draft with AI
              </button>
            ) : (
              <span className="self-center text-xs text-muted">No draft available</span>
            )}
            <button
              type="submit"
              disabled={submittingReply}
              className="rounded bg-brand-600 px-3 py-1 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
            >
              {submittingReply ? "Posting..." : "Post reply"}
            </button>
            <button
              type="button"
              onClick={() => {
                setReplying(false);
                setReplyBody("");
              }}
              className="rounded border border-border px-3 py-1 text-sm hover:bg-surface"
            >
              Cancel
            </button>
          </div>
        </form>
      )}
    </article>
  );
}
