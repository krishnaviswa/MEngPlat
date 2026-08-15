"use client";

import { use, useCallback, useEffect, useState } from "react";
import { ReviewCard } from "@/components/ReviewCard";
import { RequireAuth } from "@/components/RequireAuth";
import { businesses, payments, reviews, type Business, type PlacementResponse, type Review } from "@/lib/api";

/** Admin — a single business's shop name plus its full review history (every status). */
export default function AdminBusinessDrilldownPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [business, setBusiness] = useState<Business | null>(null);
  const [reviewList, setReviewList] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [placement, setPlacement] = useState<PlacementResponse | null>(null);
  const [actionError, setActionError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      const [allBusinesses, reviewData, place] = await Promise.all([
        businesses.adminAll({ page_size: 100 }),
        reviews.adminAll({ business_id: id }),
        payments.placement(id).catch(() => null),
      ]);
      setBusiness(allBusinesses.find((b) => b.id === id) ?? null);
      setReviewList(reviewData);
      setPlacement(place);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load business");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <RequireAuth role="admin">
      <div className="mx-auto max-w-4xl px-4 py-8">
        {loading && <p className="text-sm text-gray-500">Loading…</p>}
        {error && <p className="text-sm text-red-600">{error}</p>}
        {!loading && !error && !business && <p className="text-sm text-gray-500">Business not found.</p>}
        {business && (
          <>
            <h1 className="text-2xl font-bold">{business.name}</h1>
            <p className="text-gray-600">{business.city}</p>

            {placement && (
              <div className="mt-6 rounded-xl border bg-white p-4 text-sm">
                <h2 className="mb-2 font-semibold">Featured boost ledger</h2>
                <p>
                  {placement.active
                    ? `Active until ${new Date(placement.placement!.ends_at).toLocaleString()}`
                    : "No active paid placement"}
                </p>
                {placement.payment && (
                  <p className="mt-1 text-gray-700">
                    Payment {placement.payment.status}: platform ₹
                    {((placement.payment.platform_fee_paise ?? 0) / 100).toFixed(2)} · gateway ₹
                    {((placement.payment.gateway_fee_paise ?? 0) / 100).toFixed(2)} · order{" "}
                    <code>{placement.payment.provider_order_id}</code>
                  </p>
                )}
                {actionError && <p className="mt-2 text-red-600">{actionError}</p>}
                <div className="mt-3 flex flex-wrap gap-2">
                  {placement.placement && (
                    <button
                      type="button"
                      className="rounded border px-3 py-1.5"
                      onClick={async () => {
                        setActionError("");
                        try {
                          await payments.disablePlacement(placement.placement!.id);
                          await load();
                        } catch (e) {
                          setActionError(e instanceof Error ? e.message : "Disable failed");
                        }
                      }}
                    >
                      Disable placement
                    </button>
                  )}
                  {placement.payment && (
                    <button
                      type="button"
                      className="rounded border px-3 py-1.5"
                      onClick={async () => {
                        setActionError("");
                        try {
                          await payments.refundPayment(placement.payment!.id);
                          await load();
                        } catch (e) {
                          setActionError(e instanceof Error ? e.message : "Refund failed");
                        }
                      }}
                    >
                      Refund
                    </button>
                  )}
                  {placement.payment?.status === "created" && (
                    <button
                      type="button"
                      className="rounded border px-3 py-1.5"
                      onClick={async () => {
                        setActionError("");
                        try {
                          await payments.mockComplete(placement.payment!.provider_order_id, "paid");
                          await load();
                        } catch (e) {
                          setActionError(e instanceof Error ? e.message : "Mock complete failed");
                        }
                      }}
                    >
                      Complete mock (DEBUG)
                    </button>
                  )}
                </div>
                <p className="mt-2 text-xs text-gray-500">Customers are not charged. Event grants are not offered here.</p>
              </div>
            )}

            <div className="mt-8">
              <h2 className="mb-3 text-lg font-semibold">Review history</h2>
              {reviewList.length === 0 ? (
                <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
                  No reviews yet
                </p>
              ) : (
                <div className="space-y-4">
                  {reviewList.map((r) => (
                    <ReviewCard key={r.id} review={r} showActions={false} showSentimentBadge />
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </RequireAuth>
  );
}
