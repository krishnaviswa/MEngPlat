"use client";

import { useState } from "react";
import { RatingWidget } from "./ui/RatingWidget";
import { API_URL } from "@/lib/api";
import type { Review } from "@/lib/api";

interface ReviewCardProps {
  review: Review;
  onLike?: (id: string) => void;
  onReport?: (id: string, reason: string) => void;
  showActions?: boolean;
  canReply?: boolean;
  onReply?: (id: string, body: string) => void;
  /** Admin-only: render review.business as a link to its admin drill-down. */
  showBusinessLink?: boolean;
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
}: ReviewCardProps) {
  const [reporting, setReporting] = useState(false);
  const [reportReason, setReportReason] = useState("");
  const [replying, setReplying] = useState(false);
  const [replyBody, setReplyBody] = useState("");
  const [submittingReply, setSubmittingReply] = useState(false);

  const sentiment = review.ai_analysis?.sentiment;
  const sentimentColor =
    sentiment === "positive" ? "bg-green-100 text-green-800" :
    sentiment === "negative" ? "bg-red-100 text-red-800" :
    "bg-gray-100 text-gray-800";

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
    <article className="rounded-xl border bg-white p-4 shadow-sm">
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
            <img key={url} src={resolveUrl(url)} alt="" className="h-16 w-16 rounded object-cover" />
          ))}
        </div>
      )}
      {showActions && (
        <div className="mt-3 flex gap-3 text-sm text-gray-500">
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
        <form onSubmit={submitReport} className="mt-3 space-y-2 rounded border border-red-100 bg-red-50 p-3">
          <textarea
            required
            minLength={10}
            value={reportReason}
            onChange={(e) => setReportReason(e.target.value)}
            placeholder="Why are you reporting this review? (min 10 characters)"
            className="w-full rounded border px-2 py-1 text-sm"
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
              className="rounded border px-3 py-1 text-sm hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </form>
      )}
      {review.reply && (
        <div className="mt-3 rounded border-l-2 border-brand-300 bg-gray-50 p-3">
          <p className="text-xs font-medium text-gray-500">Response from the business</p>
          <p className="mt-1 text-sm text-gray-700">{review.reply.body}</p>
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
        <form onSubmit={submitReply} className="mt-3 space-y-2 rounded border p-3">
          <textarea
            required
            minLength={5}
            value={replyBody}
            onChange={(e) => setReplyBody(e.target.value)}
            placeholder="Write a response to this review"
            className="w-full rounded border px-2 py-1 text-sm"
            rows={2}
          />
          <div className="flex gap-2">
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
              className="rounded border px-3 py-1 text-sm hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </form>
      )}
    </article>
  );
}
