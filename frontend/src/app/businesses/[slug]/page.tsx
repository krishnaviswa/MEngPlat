import { BusinessHours } from "@/components/BusinessHours";
import { BusinessMap } from "@/components/BusinessMapClient";
import { CategoryBadges } from "@/components/CategoryBadges";
import { FavoriteButton } from "@/components/FavoriteButton";
import { PhotoGallery } from "@/components/PhotoGallery";
import { RatingWidget } from "@/components/ui/RatingWidget";
import { ReviewHighlights } from "@/components/ReviewHighlights";
import { ReviewsList } from "@/components/ReviewsList";
import { Card } from "@/components/ui/Card";
import { API_URL, businesses, photos as photosApi, reviews } from "@/lib/api";

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

  const hasCategories = (business.categories?.length ?? 0) > 0;
  const hasContactInfo = Boolean(business.email || business.website);
  const hasHours = Boolean(business.business_hours && Object.keys(business.business_hours).length > 0);
  const hasDetails = hasCategories || hasContactInfo || hasHours;

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
            {/* S-011: favorite toggle — keep separate from S-012 Details section below */}
            <div className="mt-3">
              <FavoriteButton businessId={business.id} />
            </div>
          </div>
          <a
            href={`/businesses/${slug}/review`}
            className="flex flex-col items-center rounded bg-brand-600 px-4 py-2 text-center text-white hover:bg-brand-700"
          >
            <span>✏️ Write a review</span>
            <span className="text-xs font-normal text-brand-100">takes 2 min</span>
          </a>
        </div>
        {business.description && <p className="mt-4 text-gray-700">{business.description}</p>}
        {business.ai_merchant_summary && (
          <div className="mt-4 rounded border-l-4 border-brand-400 bg-brand-50 p-3">
            <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">About this place</p>
            <p className="mt-1 text-sm text-gray-700">{business.ai_merchant_summary}</p>
          </div>
        )}
      </div>

      {hasDetails && (
        <section className="mt-8">
          <h2 className="mb-3 text-xl font-semibold">Details</h2>
          <Card className="space-y-4">
            {hasCategories && (
              <div>
                <h3 className="mb-1.5 text-sm font-semibold text-gray-700">Categories</h3>
                <CategoryBadges categories={business.categories} />
              </div>
            )}
            {hasContactInfo && (
              <div className="space-y-1 text-sm">
                {business.email && (
                  <p>
                    <a href={`mailto:${business.email}`} className="text-brand-600 hover:underline">
                      {business.email}
                    </a>
                  </p>
                )}
                {business.website && (
                  <p>
                    <a
                      href={business.website}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-brand-600 hover:underline"
                    >
                      {business.website}
                    </a>
                  </p>
                )}
              </div>
            )}
            {hasHours && (
              <div>
                <h3 className="mb-1.5 text-sm font-semibold text-gray-700">Hours</h3>
                <BusinessHours hours={business.business_hours} />
              </div>
            )}
          </Card>
        </section>
      )}

      {business.latitude != null && business.longitude != null && (        <section className="mt-8">
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
          <>
            {reviewList.length >= 3 && <ReviewHighlights reviews={reviewList} averageRating={business.average_rating} />}
            <ReviewsList initialReviews={reviewList} />
          </>
        )}
      </section>
    </div>
  );
}
