import { fireEvent, render, screen } from "@testing-library/react";
import { ReviewsList } from "@/components/ReviewsList";
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

// S-046 AC 1: sort control re-orders the list without a full page reload.
describe("ReviewsList sort (S-046 AC 1)", () => {
  const reviews: Review[] = [
    makeReview({ id: "r1", rating: 3, created_at: "2024-01-01T00:00:00Z", author: { full_name: "Alice" } as never }),
    makeReview({ id: "r2", rating: 5, created_at: "2024-03-01T00:00:00Z", author: { full_name: "Bob" } as never }),
    makeReview({ id: "r3", rating: 4, created_at: "2024-02-01T00:00:00Z", author: { full_name: "Carol" } as never }),
  ];

  it("defaults to Newest first", () => {
    render(<ReviewsList initialReviews={reviews} />);
    const articles = screen.getAllByRole("article");
    expect(articles).toHaveLength(3);
    expect(articles[0].textContent).toContain("Bob");
    expect(articles[1].textContent).toContain("Carol");
    expect(articles[2].textContent).toContain("Alice");
  });

  it("re-orders to Oldest first when sort control changes, with no page reload", () => {
    render(<ReviewsList initialReviews={reviews} />);
    fireEvent.change(screen.getByLabelText("Sort reviews"), { target: { value: "oldest" } });
    const articles = screen.getAllByRole("article");
    expect(articles[0].textContent).toContain("Alice");
    expect(articles[1].textContent).toContain("Carol");
    expect(articles[2].textContent).toContain("Bob");
  });

  it("re-orders to Highest rating first", () => {
    render(<ReviewsList initialReviews={reviews} />);
    fireEvent.change(screen.getByLabelText("Sort reviews"), { target: { value: "highest" } });
    const articles = screen.getAllByRole("article");
    expect(articles[0].textContent).toContain("Bob"); // rating 5
    expect(articles[2].textContent).toContain("Alice"); // rating 3
  });
});

// S-046 AC 2 & 3: min-rating filter, combinable with sort, and the distinct
// zero-results empty state (separate from the "no reviews yet" state).
describe("ReviewsList min-rating filter (S-046 AC 2 & 3)", () => {
  const reviews: Review[] = [
    makeReview({ id: "r1", rating: 3, created_at: "2024-01-01T00:00:00Z", author: { full_name: "Alice" } as never }),
    makeReview({ id: "r2", rating: 5, created_at: "2024-03-01T00:00:00Z", author: { full_name: "Bob" } as never }),
    makeReview({ id: "r3", rating: 4, created_at: "2024-02-01T00:00:00Z", author: { full_name: "Carol" } as never }),
  ];

  it("hides reviews below the selected minimum rating", () => {
    render(<ReviewsList initialReviews={reviews} />);
    fireEvent.click(screen.getByRole("button", { name: "4+" }));
    const articles = screen.getAllByRole("article");
    expect(articles).toHaveLength(2);
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  it("combines the min-rating filter with the sort control at the same time", () => {
    render(<ReviewsList initialReviews={reviews} />);
    fireEvent.click(screen.getByRole("button", { name: "4+" }));
    fireEvent.change(screen.getByLabelText("Sort reviews"), { target: { value: "lowest" } });
    const articles = screen.getAllByRole("article");
    expect(articles).toHaveLength(2);
    expect(articles[0].textContent).toContain("Carol"); // rating 4, lowest-first among 4/5
    expect(articles[1].textContent).toContain("Bob"); // rating 5
  });

  it("shows a distinct 'no reviews match these filters' empty state when the filter yields zero results, not the 'no reviews yet' copy", () => {
    const lowReviews: Review[] = [
      makeReview({ id: "r1", rating: 3, author: { full_name: "Alice" } as never }),
      makeReview({ id: "r2", rating: 4, author: { full_name: "Carol" } as never }),
    ];
    render(<ReviewsList initialReviews={lowReviews} />);
    fireEvent.click(screen.getByRole("button", { name: "5" }));
    expect(screen.getByText("No reviews match these filters.")).toBeInTheDocument();
    expect(screen.queryByText("No reviews yet. Be the first!")).not.toBeInTheDocument();
    expect(screen.queryAllByRole("article")).toHaveLength(0);
  });

  it("'Clear filters' resets minRating and restores the full list", () => {
    const lowReviews: Review[] = [
      makeReview({ id: "r1", rating: 3, author: { full_name: "Alice" } as never }),
      makeReview({ id: "r2", rating: 4, author: { full_name: "Carol" } as never }),
    ];
    render(<ReviewsList initialReviews={lowReviews} />);
    fireEvent.click(screen.getByRole("button", { name: "5" }));
    expect(screen.getByText("No reviews match these filters.")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Clear filters" }));
    expect(screen.queryByText("No reviews match these filters.")).not.toBeInTheDocument();
    expect(screen.getAllByRole("article")).toHaveLength(2);
  });
});
