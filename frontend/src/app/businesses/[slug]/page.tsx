import { PhotoGallery } from "@/components/PhotoGallery";
import { RatingWidget } from "@/components/RatingWidget";
import { ReviewCard } from "@/components/ReviewCard";
import { API_URL, businesses, reviews } from "@/lib/api";

interface Props {
  params: Promise<{ slug: string }>;
}

/** Business profile — SSR dynamic route. */
export default async function BusinessPage({ params }: Props) {
  const { slug } = await params;
  let business: Awaited<ReturnType<typeof businesses.get>> | null = null;
  let reviewList: Awaited<ReturnType<typeof reviews.list>> = [];

  try {
    business = await businesses.get(slug);
    reviewList = await reviews.list(business.id);
  } catch {
    return (
      <div className="mx-auto max-w-3xl px-4 py-16 text-center">
        <h1 className="text-2xl font-bold">Business not found</h1>
        <a href="/search" className="mt-4 inline-block text-brand-600">Back to search</a>
      </div>
    );
  }

  const photos = [business.storefront_url, business.logo_url].filter(Boolean) as string[];

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      <div className="rounded-xl border bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold">{business.name}</h1>
            <p className="text-gray-600">{business.address}, {business.city}</p>
            <div className="mt-2 flex items-center gap-2">
              <RatingWidget value={business.average_rating} readonly />
              <span className="text-sm text-gray-500">({business.review_count} reviews)</span>
            </div>
          </div>
          <a
            href={`/businesses/${slug}/review`}
            className="rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700"
          >
            Write a review
          </a>
        </div>
        {business.description && <p className="mt-4 text-gray-700">{business.description}</p>}
        {business.ai_merchant_summary && (
          <p className="mt-4 rounded bg-brand-50 p-3 text-sm">
            <strong>AI overview (suggestion):</strong> {business.ai_merchant_summary}
          </p>
        )}
      </div>
      {photos.length > 0 && (
        <section className="mt-8">
          <h2 className="mb-3 text-xl font-semibold">Photos</h2>
          <PhotoGallery photos={photos.map((p) => (p.startsWith("http") ? p : `${API_URL}${p}`))} />
        </section>
      )}
      <section className="mt-8">
        <h2 className="mb-4 text-xl font-semibold">Reviews</h2>
        <div className="space-y-4">
          {reviewList.length ? (
            reviewList.map((r) => <ReviewCard key={r.id} review={r} showActions={false} />)
          ) : (
            <p className="text-gray-500">No reviews yet. Be the first!</p>
          )}
        </div>
      </section>
    </div>
  );
}
