import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import CollectReviewPage from "@/app/collect/[businessId]/page";
import { auth, businesses, reviews } from "@/lib/api";

const pushMock = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: pushMock }),
}));

jest.mock("../../../../lib/api", () => ({
  API_URL: "http://localhost:8000",
  auth: { me: jest.fn(), phoneRequest: jest.fn(), phoneVerify: jest.fn() },
  businesses: { get: jest.fn(), getById: jest.fn() },
  reviews: { create: jest.fn(), list: jest.fn() },
  storeTokens: jest.fn(),
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

  // S-121 AC2/AC6/AC7: unauthenticated submit swaps the frozen "text" screen
  // for the inline auth step in place (no navigation, no reset of gamified
  // screen state); completing it auto-submits the same composed review and
  // reaches the gamified celebration, with the compose form never re-shown.
  it("shows the inline auth step in place and auto-submits after phone-OTP sign-in, reaching the celebration (S-121)", async () => {
    (auth.me as jest.Mock).mockRejectedValue(new Error("unauthorized"));
    (auth.phoneRequest as jest.Mock).mockResolvedValue({ message: "sent" });
    (auth.phoneVerify as jest.Mock).mockResolvedValue({ access_token: "a1", refresh_token: "r1" });
    (reviews.create as jest.Mock).mockResolvedValue({
      id: "r3",
      status: "active",
      rating: 3,
      body: "Average visit overall.",
    });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");

    clickStar(3);
    fireEvent.click(await screen.findByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Average visit overall." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText(/sign in to post your review/i)).toBeInTheDocument();
    expect(reviews.create).not.toHaveBeenCalled();
    // Composed text step is gone from the DOM while auth is pending, but the
    // gamified `screen` state stays frozen at "text" underneath (untouched by
    // authPending), not reset back to "stars".
    expect(screen.queryByPlaceholderText(/share what made your visit memorable/i)).not.toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(auth.phoneRequest).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() =>
      expect(reviews.create).toHaveBeenCalledWith({
        business_id: "b1",
        rating: 3,
        body: "Average visit overall.",
      }),
    );
    expect(await screen.findByText(/review submitted!/i)).toBeInTheDocument();
    // No re-entry: neither the inline auth step nor the text-step form reappear.
    expect(screen.queryByText(/sign in to post your review/i)).not.toBeInTheDocument();
    expect(screen.queryByPlaceholderText(/share what made your visit memorable/i)).not.toBeInTheDocument();
  });
});
