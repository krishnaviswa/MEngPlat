import { ReviewForm } from "@/components/ReviewForm";
import { PageHeading } from "@/components/ui/PageHeading";
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
        <PageHeading>Business not found</PageHeading>
        <a href="/search" className="mt-4 inline-block text-brand-600">Back to search</a>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <PageHeading>Write a review</PageHeading>
      <p className="mt-1 text-muted">for {business.name}</p>
      <div className="mt-6">
        <ReviewForm business={business} />
      </div>
    </div>
  );
}
