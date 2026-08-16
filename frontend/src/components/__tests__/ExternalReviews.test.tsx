import { render, screen } from "@testing-library/react";
import { ExternalReviews } from "@/components/ExternalReviews";
import type { ExternalReview } from "@/lib/api";

function makeExternalReview(overrides: Partial<ExternalReview> = {}): ExternalReview {
  return {
    id: "ext-1",
    author_name: "Asha Rao",
    author_photo_url: null,
    rating: 5,
    body: "Fantastic service, will be back again!",
    source: "google",
    source_url: "https://maps.google.com/?cid=1",
    external_posted_at: "2026-06-01T00:00:00Z",
    ...overrides,
  };
}

// S-048 AC10, AC11, AC15
describe("ExternalReviews", () => {
  it("returns null (no placeholder box) when there are zero external reviews", () => {
    const { container } = render(<ExternalReviews reviews={[]} />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders the 'Also reviewed on Google' heading and each review when present", () => {
    const reviews = [
      makeExternalReview({ id: "ext-1", author_name: "Asha Rao" }),
      makeExternalReview({ id: "ext-2", author_name: "Vikram Singh", rating: 4, body: "Good experience." }),
    ];
    render(<ExternalReviews reviews={reviews} />);

    expect(screen.getByText("Also reviewed on Google")).toBeInTheDocument();
    expect(screen.getByText("Asha Rao")).toBeInTheDocument();
    expect(screen.getByText("Vikram Singh")).toBeInTheDocument();
    expect(screen.getByText("Fantastic service, will be back again!")).toBeInTheDocument();
    expect(screen.getByText("Good experience.")).toBeInTheDocument();
  });

  // AC15: honest caveat about Google's 5-review cap, not implied to be a full history.
  it("states the up-to-5 curated-sample caveat, not a full review history", () => {
    render(<ExternalReviews reviews={[makeExternalReview()]} />);
    expect(screen.getByText(/up to 5 most-relevant google reviews/i)).toBeInTheDocument();
  });

  // Google allows rating-only, textless reviews -- the nullable-body path.
  it("shows an italic 'No written review' fallback when body is null", () => {
    render(<ExternalReviews reviews={[makeExternalReview({ body: null })]} />);
    expect(screen.getByText("No written review")).toBeInTheDocument();
  });

  it("links out to the Google listing via source_url", () => {
    render(<ExternalReviews reviews={[makeExternalReview({ source_url: "https://maps.google.com/?cid=42" })]} />);
    const link = screen.getByRole("link", { name: /view on google/i });
    expect(link).toHaveAttribute("href", "https://maps.google.com/?cid=42");
    expect(link).toHaveAttribute("target", "_blank");
  });

  it("does not render a 'View on Google' link when source_url is null", () => {
    render(<ExternalReviews reviews={[makeExternalReview({ source_url: null })]} />);
    expect(screen.queryByRole("link", { name: /view on google/i })).not.toBeInTheDocument();
  });
});
