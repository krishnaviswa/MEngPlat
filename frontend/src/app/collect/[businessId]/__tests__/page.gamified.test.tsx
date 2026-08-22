import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import CollectReviewPage from "@/app/collect/[businessId]/page";
import { auth, businesses, reviews } from "@/lib/api";

const pushMock = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: pushMock }),
}));

jest.mock("../../../../lib/api", () => ({
  API_URL: "http://localhost:8000",
  auth: { me: jest.fn() },
  businesses: { get: jest.fn(), getById: jest.fn() },
  reviews: { create: jest.fn(), list: jest.fn() },
}));

const cafe = {
  id: "b1",
  name: "Cafe",
  city: "Chennai",
  slug: "cafe",
  address: "12 MG Road",
  logo_url: "/uploads/cafe-logo.png",
  average_rating: 4,
  review_count: 1,
};

function resolvedParams(value: { businessId: string }): Promise<{ businessId: string }> {
  return { status: "fulfilled", value, then() {} } as unknown as Promise<{ businessId: string }>;
}

function clickStar(count: number) {
  const buttons = screen.getAllByRole("button", { name: `${count} stars` });
  const interactive = buttons.find((b) => !b.hasAttribute("disabled"));
  fireEvent.click(interactive!);
}

describe("Collect review wizard — gamified flow (S-119)", () => {
  const originalFlag = process.env.NEXT_PUBLIC_GAMIFIED_REVIEW;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.NEXT_PUBLIC_GAMIFIED_REVIEW = "true";
    (businesses.get as jest.Mock).mockResolvedValue(cafe);
    (businesses.getById as jest.Mock).mockResolvedValue(cafe);
    (reviews.list as jest.Mock).mockResolvedValue([]);
  });

  afterEach(() => {
    process.env.NEXT_PUBLIC_GAMIFIED_REVIEW = originalFlag;
  });

  it("walks stars -> chips -> text one screen at a time via tap only, no gating on low ratings", async () => {
    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");

    expect(screen.getByText(/how was your experience/i)).toBeInTheDocument();
    clickStar(1); // lowest rating must reach the same next step as any other
    expect(await screen.findByText(/what stood out/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Service" }));
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));

    expect(await screen.findByText(/write your review/i)).toBeInTheDocument();
  });

  it("submits through the existing API and shows a celebration before the normal done screen", async () => {
    (auth.me as jest.Mock).mockResolvedValue({ id: "c1", role: "customer" });
    (reviews.create as jest.Mock).mockResolvedValue({
      id: "r1",
      status: "active",
      rating: 5,
      body: "Loved the espresso here.",
    });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");

    clickStar(5);
    fireEvent.click(await screen.findByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Loved the espresso here." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    await waitFor(() =>
      expect(reviews.create).toHaveBeenCalledWith({
        business_id: "b1",
        rating: 5,
        body: "Loved the espresso here.",
      }),
    );

    expect(await screen.findByText(/review submitted!/i)).toBeInTheDocument();
    expect(screen.queryByText(/your review is live/i)).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /^continue/i }));
    expect(await screen.findByText(/your review is live/i)).toBeInTheDocument();
  });

  it("shows an inline error and stays on the text step when submission fails, so the customer can retry", async () => {
    (auth.me as jest.Mock).mockResolvedValue({ id: "c1", role: "customer" });
    (reviews.create as jest.Mock).mockRejectedValueOnce(new Error("Network error"));

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");

    clickStar(5);
    fireEvent.click(await screen.findByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Loved the espresso here." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText("Network error")).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/share what made your visit memorable/i)).toBeInTheDocument();
    expect(screen.queryByText(/review submitted!/i)).not.toBeInTheDocument();

    (reviews.create as jest.Mock).mockResolvedValueOnce({ id: "r1", status: "active", rating: 5, body: "Loved the espresso here." });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText(/review submitted!/i)).toBeInTheDocument();
  });
});
