import { render, screen } from "@testing-library/react";
import { AllReviewsQueue } from "@/components/admin/AllReviewsQueue";
import { reviews } from "@/lib/api";
import type { Review } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  reviews: { adminAll: jest.fn() },
}));

const adminAllMock = reviews.adminAll as jest.Mock;

function makeReview(overrides: Partial<Review> = {}): Review {
  return {
    id: "rev-1",
    business_id: "biz-1",
    rating: 4,
    body: "Solid experience overall.",
    like_count: 0,
    created_at: new Date().toISOString(),
    business: { id: "biz-1", name: "Corner Bakery", slug: "corner-bakery", city: "Chennai", status: "approved" },
    ...overrides,
  };
}

describe("AllReviewsQueue (S-021 AC 4 / AC 5)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC 5: each review row shows the business's shop name as a clickable
  // link/element that opens that business's drill-down.
  it("renders each review with a clickable business-name link to its drill-down", async () => {
    adminAllMock.mockResolvedValue([makeReview()]);

    render(<AllReviewsQueue />);

    const link = await screen.findByRole("link", { name: "Corner Bakery" });
    expect(link).toHaveAttribute("href", "/admin/businesses/biz-1");
  });

  // Out of scope: no new moderation actions ship on this browse view.
  it("does not render moderation action buttons (hide/restore/remove)", async () => {
    adminAllMock.mockResolvedValue([makeReview()]);

    render(<AllReviewsQueue />);

    await screen.findByText("Solid experience overall.");
    expect(screen.queryByRole("button", { name: /hide/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /restore/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /remove/i })).not.toBeInTheDocument();
  });

  it("shows a 'No reviews' empty state when the list is empty", async () => {
    adminAllMock.mockResolvedValue([]);

    render(<AllReviewsQueue />);

    expect(await screen.findByText("No reviews")).toBeInTheDocument();
  });

  it("shows an inline error message when the fetch fails", async () => {
    adminAllMock.mockRejectedValue(new Error("Network down"));

    render(<AllReviewsQueue />);

    expect(await screen.findByText("Network down")).toBeInTheDocument();
  });
});
