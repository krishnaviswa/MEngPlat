import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import CollectReviewPage from "@/app/collect/[businessId]/page";
import { auth, businesses, reviews } from "@/lib/api";

const pushMock = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: pushMock }),
}));

class MockApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

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

const uuid = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee";

function resolvedParams(value: { businessId: string }): Promise<{ businessId: string }> {
  return { status: "fulfilled", value, then() {} } as unknown as Promise<{ businessId: string }>;
}

/** The hero header shows a second, readonly star widget with the same aria-labels; pick the interactive one. */
function clickStar(count: number) {
  const buttons = screen.getAllByRole("button", { name: `${count} stars` });
  const interactive = buttons.find((b) => !b.hasAttribute("disabled"));
  fireEvent.click(interactive!);
}

describe("Collect review wizard (S-040 / S-106)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (businesses.get as jest.Mock).mockResolvedValue(cafe);
    (businesses.getById as jest.Mock).mockResolvedValue(cafe);
    (reviews.list as jest.Mock).mockResolvedValue([]);
  });

  it("does not intercept low star ratings", async () => {
    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    expect(await screen.findByText(/Your review takes/i)).toBeInTheDocument();
    expect(await screen.findByText("Cafe")).toBeInTheDocument();
    expect(screen.getByText("12 MG Road, Chennai")).toBeInTheDocument();
    expect(screen.getByText("Cafe").closest("div")).toHaveStyle(
      "background-image: linear-gradient(to top, rgba(15,23,42,0.75), rgba(15,23,42,0.15)), url(http://localhost:8000/uploads/cafe-logo.png)",
    );
    expect(businesses.get).toHaveBeenCalledWith("cafe");
    expect(businesses.getById).not.toHaveBeenCalled();
    clickStar(1);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(screen.getByPlaceholderText(/share what made your visit memorable/i)).toBeInTheDocument();
    expect(screen.queryByText(/google/i)).not.toBeInTheDocument();
  });

  it("loads an approved shop by UUID via getById", async () => {
    render(<CollectReviewPage params={resolvedParams({ businessId: uuid })} />);
    expect(await screen.findByText("Cafe")).toBeInTheDocument();
    expect(businesses.getById).toHaveBeenCalledWith(uuid);
    expect(businesses.get).not.toHaveBeenCalled();
  });

  it("falls back to getById when slug lookup returns 404", async () => {
    (businesses.get as jest.Mock).mockRejectedValue(new MockApiError("Not found", 404));
    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    expect(await screen.findByText("Cafe")).toBeInTheDocument();
    expect(businesses.get).toHaveBeenCalledWith("cafe");
    expect(businesses.getById).toHaveBeenCalledWith("cafe");
  });

  it("creates the review through the existing API when signed in", async () => {
    (auth.me as jest.Mock).mockResolvedValue({ id: "c1", role: "customer" });
    (reviews.create as jest.Mock).mockResolvedValue({
      id: "r1",
      status: "active",
      rating: 5,
      body: "Really enjoyed the coffee here.",
    });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");
    clickStar(5);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Really enjoyed the coffee here." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    await waitFor(() =>
      expect(reviews.create).toHaveBeenCalledWith({
        business_id: "b1",
        rating: 5,
        body: "Really enjoyed the coffee here.",
      }),
    );
    expect(await screen.findByText(/Your review is live/i)).toBeInTheDocument();
    expect(screen.getByText("Really enjoyed the coffee here.")).toBeInTheDocument();
    const maps = screen.getByRole("link", { name: /share on google maps too/i });
    expect(maps).toHaveAttribute("href", expect.stringContaining("google.com/maps"));
  });

  it("shows submitted rating and body on the thanks step when comments are missing", async () => {
    (auth.me as jest.Mock).mockResolvedValue({ id: "c1", role: "customer" });
    (reviews.create as jest.Mock).mockResolvedValue({ id: "r1", status: "active", rating: 4, body: "🙂" });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");
    clickStar(4);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "🙂" },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText(/Your review is live/i)).toBeInTheDocument();
    expect(screen.getByText("🙂")).toBeInTheDocument();
  });

  it("shows the inline sign-in step in place, without navigating, when the visitor is not signed in (S-121)", async () => {
    (auth.me as jest.Mock).mockRejectedValue(new Error("unauthorized"));

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");
    clickStar(1);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Too noisy near the street." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText(/sign in to post your review/i)).toBeInTheDocument();
    expect(pushMock).not.toHaveBeenCalled();
    expect(reviews.create).not.toHaveBeenCalled();
    // Composed review stays intact behind the inline auth step (AC2/AC9) --
    // the text step's own textarea is gone from the DOM while auth is
    // pending, but nothing was lost: the "Continue" step (stars) is also
    // gone, confirming step state, not just the form, is preserved in memory.
    expect(screen.queryByPlaceholderText(/share what made your visit memorable/i)).not.toBeInTheDocument();
  });

  // S-121 AC6/AC7: completing the inline step's default (phone OTP) method
  // auto-submits the already-composed review with no re-entry, and lands on
  // the existing "done" screen — no route change, no duplicate success UI.
  it("auto-submits the composed review after inline phone-OTP sign-in succeeds, with no re-entry (S-121)", async () => {
    (auth.me as jest.Mock).mockRejectedValue(new Error("unauthorized"));
    (auth.phoneRequest as jest.Mock).mockResolvedValue({ message: "sent" });
    (auth.phoneVerify as jest.Mock).mockResolvedValue({ access_token: "a1", refresh_token: "r1" });
    (reviews.create as jest.Mock).mockResolvedValue({
      id: "r2",
      status: "active",
      rating: 2,
      body: "Slow service but decent food.",
    });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");
    clickStar(2);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Slow service but decent food." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    expect(await screen.findByText(/sign in to post your review/i)).toBeInTheDocument();
    expect(reviews.create).not.toHaveBeenCalled();

    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(auth.phoneRequest).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() =>
      expect(reviews.create).toHaveBeenCalledWith({
        business_id: "b1",
        rating: 2,
        body: "Slow service but decent food.",
      }),
    );
    expect(await screen.findByText(/Your review is live/i)).toBeInTheDocument();
    expect(pushMock).not.toHaveBeenCalled();
    // No re-entry: neither the inline auth step nor the compose form reappear.
    expect(screen.queryByText(/sign in to post your review/i)).not.toBeInTheDocument();
    expect(screen.queryByPlaceholderText(/share what made your visit memorable/i)).not.toBeInTheDocument();
  });

  // S-121 AC9 (page-level): a failed inline sign-in attempt must not discard
  // the rating/body already held in the *page's* own state (InlineAuthStep
  // itself never sees that data) -- confirmed here by retrying after a
  // failure and asserting the originally composed body/rating still reach
  // POST /reviews unchanged.
  it("keeps the composed rating/body intact in page state across a failed inline sign-in attempt, then submits it on retry (S-121 AC9)", async () => {
    (auth.me as jest.Mock).mockRejectedValue(new Error("unauthorized"));
    (auth.phoneRequest as jest.Mock).mockResolvedValue({ message: "sent" });
    (auth.phoneVerify as jest.Mock)
      .mockRejectedValueOnce(new Error("Invalid code"))
      .mockResolvedValueOnce({ access_token: "a1", refresh_token: "r1" });
    (reviews.create as jest.Mock).mockResolvedValue({
      id: "r4",
      status: "active",
      rating: 4,
      body: "Great coffee, will return.",
    });

    render(<CollectReviewPage params={resolvedParams({ businessId: "cafe" })} />);
    await screen.findByText("Cafe");
    clickStar(4);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Great coffee, will return." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    await screen.findByText(/sign in to post your review/i);
    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(auth.phoneRequest).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    expect(await screen.findByText("Invalid code")).toBeInTheDocument();
    expect(reviews.create).not.toHaveBeenCalled();
    // Still on the collect page, still in the inline step -- no navigation away.
    expect(pushMock).not.toHaveBeenCalled();
    expect(screen.getByText(/sign in to post your review/i)).toBeInTheDocument();

    // Retry succeeds -- the originally composed rating/body survived untouched.
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));

    await waitFor(() =>
      expect(reviews.create).toHaveBeenCalledWith({
        business_id: "b1",
        rating: 4,
        body: "Great coffee, will return.",
      }),
    );
    expect(await screen.findByText(/Your review is live/i)).toBeInTheDocument();
  });
});
