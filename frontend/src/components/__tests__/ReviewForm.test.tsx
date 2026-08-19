import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { ReviewForm } from "@/components/ReviewForm";
import { reviews } from "../../lib/api";

const refreshMock = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: jest.fn(), refresh: refreshMock }),
}));

jest.mock("../../lib/api", () => ({
  API_URL: "http://localhost:8000",
  photos: { upload: jest.fn() },
  reviews: { create: jest.fn() },
}));

const business = {
  id: "b1",
  name: "Cafe",
  slug: "cafe",
  city: "Chennai",
  address: "12 MG Road",
  logo_url: "/uploads/cafe-logo.png",
  average_rating: 4,
  review_count: 1,
  status: "approved" as const,
};

describe("ReviewForm", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "t");
  });

  it("shows shop name and a thanks message after a live post", async () => {
    (reviews.create as jest.Mock).mockResolvedValue({ id: "r1", status: "active" });

    render(<ReviewForm business={business} />);
    expect(screen.getByText("Cafe")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "5 stars" }));
    fireEvent.change(screen.getByPlaceholderText(/share details of your experience/i), {
      target: { value: "Really enjoyed the coffee here." },
    });
    fireEvent.click(screen.getByRole("button", { name: /post review/i }));

    expect(await screen.findByText(/Thank you! Your review is live/i)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /back to cafe/i })).toHaveAttribute("href", "/businesses/cafe");
  });
});
