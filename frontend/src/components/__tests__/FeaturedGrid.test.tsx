import { render, screen } from "@testing-library/react";
import { FeaturedGrid } from "@/components/home/FeaturedGrid";
import type { Business } from "@/lib/api";

const sample: Business = {
  id: "1",
  name: "Sample Café",
  slug: "sample-cafe",
  address: "1 Main St",
  city: "Chennai",
  average_rating: 4.5,
  review_count: 3,
};

describe("FeaturedGrid", () => {
  it("renders business cards when listings are present", () => {
    render(
      <FeaturedGrid
        businesses={[sample]}
        title="Featured businesses"
        subtitle="Photos and ratings"
        viewAllHref="/search"
        viewAllLabel="View all"
      />,
    );
    expect(screen.getByText("Sample Café")).toBeInTheDocument();
    expect(screen.queryByText(/Could not load businesses/i)).not.toBeInTheDocument();
  });

  it("surfaces SSR loadError with API URL guidance", () => {
    render(
      <FeaturedGrid
        businesses={[]}
        title="Featured businesses"
        subtitle="Photos and ratings"
        viewAllHref="/search"
        viewAllLabel="View all"
        loadError="API_URL=http://localhost:8000 — businesses.list: fetch failed"
      />,
    );
    expect(screen.getByText(/Could not load businesses from the API/i)).toBeInTheDocument();
    expect(screen.getByText(/API_URL_INTERNAL/)).toBeInTheDocument();
    expect(screen.getByText(/does not appear in deploy logs/i)).toBeInTheDocument();
    expect(screen.getByText(/API_URL=http:\/\/localhost:8000/)).toBeInTheDocument();
  });

  it("shows seed-via-shell guidance when empty without loadError", () => {
    render(
      <FeaturedGrid
        businesses={[]}
        title="Featured businesses"
        subtitle="Photos and ratings"
        viewAllHref="/search"
        viewAllLabel="View all"
      />,
    );
    expect(screen.getByText(/No businesses loaded yet/i)).toBeInTheDocument();
    expect(screen.getByText(/SEED_MODE=force/)).toBeInTheDocument();
  });
});
