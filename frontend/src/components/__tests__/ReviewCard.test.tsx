import { fireEvent, render, screen } from "@testing-library/react";
import { ReviewCard } from "@/components/ReviewCard";
import type { Review } from "@/lib/api";

function makeReview(overrides: Partial<Review> = {}): Review {
  return {
    id: "rev-1",
    business_id: "biz-1",
    rating: 5,
    body: "Loved the service here.",
    like_count: 2,
    created_at: new Date().toISOString(),
    ...overrides,
  };
}

// S-021 AC 5 / AC 8: the business-name link is admin-only and gated behind an
// explicit `showBusinessLink` prop -- `review.business` is now populated on
// every review-listing endpoint (including the public business-detail page's
// review list), so presence of `review.business` alone must never be enough
// to render the link on a non-admin call site.
describe("ReviewCard business link gating (S-021)", () => {
  const business = { id: "biz-1", name: "Cafe Luna", slug: "cafe-luna", city: "Chennai", status: "approved" as const };

  it("does not render a business-name link when showBusinessLink is omitted, even if review.business is present", () => {
    render(<ReviewCard review={makeReview({ business })} />);

    expect(screen.queryByRole("link", { name: "Cafe Luna" })).not.toBeInTheDocument();
  });

  it("does not render a business-name link when showBusinessLink is explicitly false", () => {
    render(<ReviewCard review={makeReview({ business })} showBusinessLink={false} />);

    expect(screen.queryByRole("link", { name: "Cafe Luna" })).not.toBeInTheDocument();
  });

  it("renders a business-name link to the admin drill-down when showBusinessLink is true and review.business is present", () => {
    render(<ReviewCard review={makeReview({ business })} showBusinessLink />);

    const link = screen.getByRole("link", { name: "Cafe Luna" });
    expect(link).toHaveAttribute("href", "/admin/businesses/biz-1");
  });

  it("renders no business link when showBusinessLink is true but review.business is absent, and does not crash", () => {
    render(<ReviewCard review={makeReview()} showBusinessLink />);

    expect(screen.queryByRole("link")).not.toBeInTheDocument();
  });
});

// S-021 AC 8 (regression, not new behavior): the AI sentiment badge and
// "suggestion" disclaimer copy must remain exactly as-is -- this slice
// reuses ReviewCard's existing rendering, introducing no new AI surface or
// definitive-judgment language.
describe("ReviewCard AI disclaimer language (regression, S-021 AC 8)", () => {
  it("renders the 'AI: {sentiment}' badge when ai_analysis.sentiment is present and showSentimentBadge is set (internal-audience views only)", () => {
    render(<ReviewCard review={makeReview({ ai_analysis: { sentiment: "positive" } })} showSentimentBadge />);

    expect(screen.getByText("AI: positive")).toBeInTheDocument();
  });

  it("hides the AI sentiment badge by default (customer-facing views)", () => {
    render(<ReviewCard review={makeReview({ ai_analysis: { sentiment: "positive" } })} />);

    expect(screen.queryByText("AI: positive")).not.toBeInTheDocument();
  });

  it("renders the 'Quick take' disclaimer when ai_analysis.summary is present", () => {
    render(
      <ReviewCard
        review={makeReview({ ai_analysis: { sentiment: "positive", summary: "Customers love the coffee." } })}
      />,
    );

    expect(screen.getByText("Quick take:")).toBeInTheDocument();
    expect(screen.getByText(/Customers love the coffee\./)).toBeInTheDocument();
  });

  it("renders no AI badge or summary when ai_analysis is absent", () => {
    render(<ReviewCard review={makeReview()} showSentimentBadge />);

    expect(screen.queryByText(/^AI:/)).not.toBeInTheDocument();
    expect(screen.queryByText("Quick take:")).not.toBeInTheDocument();
  });

  it("fills the reply box from suggested_response as a suggestion", () => {
    render(
      <ReviewCard
        review={makeReview({
          ai_analysis: { sentiment: "positive", suggested_response: "Thanks for visiting — suggestion only." },
        })}
        canReply
        onReply={jest.fn()}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /reply as business/i }));
    fireEvent.click(screen.getByRole("button", { name: /draft with ai/i }));
    expect(screen.getByDisplayValue(/Thanks for visiting/)).toBeInTheDocument();
    expect(screen.getByText(/AI draft is a suggestion/i)).toBeInTheDocument();
    expect(screen.getByText(/not posted automatically/i)).toBeInTheDocument();
  });
});

describe("ReviewCard AI reply drafting (S-039)", () => {
  it("shows 'No draft available' when suggested_response is missing", () => {
    render(
      <ReviewCard
        review={makeReview({ ai_analysis: { sentiment: "neutral" } })}
        canReply
        onReply={jest.fn()}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /reply as business/i }));
    expect(screen.getByText("No draft available")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /draft with ai/i })).not.toBeInTheDocument();
  });

  it("posts the edited textarea, not the original AI draft", async () => {
    const onReply = jest.fn().mockResolvedValue(undefined);
    render(
      <ReviewCard
        review={makeReview({
          ai_analysis: { sentiment: "positive", suggested_response: "Thanks for visiting — suggestion only." },
        })}
        canReply
        onReply={onReply}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /reply as business/i }));
    fireEvent.click(screen.getByRole("button", { name: /draft with ai/i }));
    fireEvent.change(screen.getByDisplayValue(/Thanks for visiting/), {
      target: { value: "Edited by the merchant before send." },
    });
    fireEvent.click(screen.getByRole("button", { name: /post reply/i }));
    expect(onReply).toHaveBeenCalledWith("rev-1", "Edited by the merchant before send.");
    expect(onReply).not.toHaveBeenCalledWith("rev-1", "Thanks for visiting — suggestion only.");
  });

  it("hides Draft with AI when canReply is omitted (customer view)", () => {
    render(
      <ReviewCard
        review={makeReview({
          ai_analysis: { sentiment: "positive", suggested_response: "Thanks for visiting — suggestion only." },
        })}
      />,
    );
    expect(screen.queryByRole("button", { name: /reply as business/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /draft with ai/i })).not.toBeInTheDocument();
    expect(screen.queryByText(/AI draft is a suggestion/i)).not.toBeInTheDocument();
  });
});
