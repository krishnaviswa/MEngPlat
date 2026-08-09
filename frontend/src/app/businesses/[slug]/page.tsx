import { PhotoGallery } from "@/components/PhotoGallery";
import { RatingWidget } from "@/components/RatingWidget";
import { ReviewsList } from "@/components/ReviewsList";
import { API_URL, businesses, photos as photosApi, reviews } from "@/lib/api";
import dynamic from "next/dynamic";

const BusinessMap = dynamic(() => import("@/components/BusinessMap"), { ssr: false });

interface Props {
  params: Promise<{ slug: string }>;
}

/** Business profile — SSR dynamic route with Maps-style header photo and location. */
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
        <a href="/search" className="mt-4 inline-block text-brand-600">
          Back to search
        </a>
      </div>
    );
  }

  const galleryPhotos = await photosApi.listForBusiness(business.id).catch(() => []);
  const photos = galleryPhotos.length
    ? galleryPhotos.map((p) => p.url)
    : ([business.storefront_url, business.logo_url].filter(Boolean) as string[]);

  const hero = business.storefront_url || photos[0];
  const placeLine = [business.address, business.city, business.state, business.postal_code]
    .filter(Boolean)
    .join(", ");

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      {hero && (
        <div className="mb-6 overflow-hidden rounded-xl border bg-white shadow-sm">
          <img
            src={hero.startsWith("http") ? hero : `${API_URL}${hero}`}
            alt=""
            className="h-56 w-full object-cover sm:h-72"
          />
        </div>
      )}

      <div className="rounded-xl border bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="text-sm font-medium text-brand-700">
              {business.categories?.[0]?.name || "Local business"}
            </p>
            <h1 className="mt-1 text-3xl font-bold">{business.name}</h1>
            <p className="mt-2 text-gray-700">{placeLine}</p>
            {business.phone && <p className="mt-1 text-sm text-gray-600">{business.phone}</p>}
            <div className="mt-3 flex items-center gap-2">
              <RatingWidget value={business.average_rating} readonly />
              <span className="text-sm font-semibold text-gray-800">
                {business.average_rating ? business.average_rating.toFixed(1) : "New"}
              </span>
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

      {business.latitude != null && business.longitude != null && (
        <section className="mt-8">
          <h2 className="mb-3 text-xl font-semibold">Location</h2>
          <BusinessMap
            markers={[
              {
                id: business.id,
                name: business.name,
                slug: business.slug,
                latitude: business.latitude,
                longitude: business.longitude,
              },
            ]}
            zoom={15}
            height="280px"
          />
        </section>
      )}

      {photos.length > 0 && (
        <section className="mt-8">
          <h2 className="mb-3 text-xl font-semibold">Photos</h2>
          <PhotoGallery photos={photos.map((p) => (p.startsWith("http") ? p : `${API_URL}${p}`))} />
        </section>
      )}

      <section className="mt-8">
        <h2 className="mb-4 text-xl font-semibold">Reviews</h2>
        {reviewList.length === 0 ? (
          <p className="text-gray-500">No reviews yet — be the first to share your experience.</p>
        ) : (
          <ReviewsList initialReviews={reviewList} />
        )}
      </section>
    </div>
  );
}
