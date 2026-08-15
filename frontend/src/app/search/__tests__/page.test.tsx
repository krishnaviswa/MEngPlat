import { render, screen } from "@testing-library/react";
import SearchPage from "@/app/search/page";
import { businesses } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  businesses: { search: jest.fn(), categoriesAll: jest.fn(), cities: jest.fn() },
}));

jest.mock("../../../components/FilterPanel", () => ({
  FilterPanel: () => <div>filters</div>,
}));
jest.mock("../../../components/SearchBar", () => ({
  SearchBar: () => <div>searchbar</div>,
}));
jest.mock("../../../components/UseLocationButton", () => ({
  UseLocationButton: () => null,
}));
jest.mock("../../../components/BusinessMapClient", () => ({
  BusinessMap: () => null,
}));

describe("Search featured ranking copy (S-036)", () => {
  it("states Featured is a paid 7-day boost, not an AI verdict", async () => {
    (businesses.search as jest.Mock).mockResolvedValue([
      {
        id: "b1",
        name: "Cafe",
        slug: "cafe",
        address: "1 St",
        city: "Chennai",
        average_rating: 4,
        review_count: 2,
        is_featured: true,
      },
    ]);
    (businesses.categoriesAll as jest.Mock).mockResolvedValue([]);
    (businesses.cities as jest.Mock).mockResolvedValue(["Chennai"]);

    const ui = await SearchPage({ searchParams: Promise.resolve({}) });
    render(ui);

    expect(screen.getByText(/paid for a 7-day search boost/i)).toBeInTheDocument();
    expect(screen.getByText(/not an AI quality score/i)).toBeInTheDocument();
    expect(screen.getByText(/does not mean the business is better/i)).toBeInTheDocument();
    expect(screen.getAllByText("Featured").length).toBeGreaterThanOrEqual(2);
    expect(screen.queryByRole("button", { name: /pay|checkout|boost/i })).not.toBeInTheDocument();
  });
});
