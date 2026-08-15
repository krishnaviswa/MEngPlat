import { render, screen } from "@testing-library/react";
import { BusinessCard } from "@/components/BusinessCard";
import type { Business } from "@/lib/api";

const business: Business = {
  id: "b1",
  name: "Cafe",
  slug: "cafe",
  address: "1 St",
  city: "Chennai",
  average_rating: 4,
  review_count: 2,
};

describe("BusinessCard featured badge", () => {
  it("does not show Featured unless is_featured", () => {
    render(<BusinessCard business={business} />);
    expect(screen.queryByText("Featured")).not.toBeInTheDocument();
  });

  it("shows Featured badge for paid placement", () => {
    render(<BusinessCard business={{ ...business, is_featured: true }} />);
    expect(screen.getByText("Featured")).toBeInTheDocument();
  });
});
