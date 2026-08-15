import { ReviewForm } from "@/components/ReviewForm";
import { businesses } from "@/lib/api";

interface Props {
  params: Promise<{ slug: string }>;
}

/** Write-a-review page — SSR dynamic route. */
export default async function WriteReviewPage({ params }: Props) {
  const { slug } = await params;
  let business: Awaited<ReturnType<typeof businesses.get>> | null = null;

  try {
    business = await businesses.get(slug);
  } catch {
    return (
      <div className="mx-auto max-w-3xl px-4 py-16 text-center">
        <h1 className="text-2xl font-bold">Business not found</h1>
        <a href="/search" className="mt-4 inline-block text-brand-600">Back to search</a>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <h1 className="text-2xl font-bold">Write a review</h1>
      <p className="mt-1 text-muted">for {business.name}</p>
      <div className="mt-6">
        <ReviewForm business={business} />
      </div>
    </div>
  );
}
