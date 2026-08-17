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
  businesses: { list: jest.fn() },
  reviews: { create: jest.fn(), list: jest.fn() },
}));

function resolvedParams(value: { businessId: string }): Promise<{ businessId: string }> {
  return { status: "fulfilled", value, then() {} } as unknown as Promise<{ businessId: string }>;
}

/** The hero header shows a second, readonly star widget with the same aria-labels; pick the interactive one. */
function clickStar(count: number) {
  const buttons = screen.getAllByRole("button", { name: `${count} stars` });
  const interactive = buttons.find((b) => !b.hasAttribute("disabled"));
  fireEvent.click(interactive!);
}

describe("Collect review wizard (S-040)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (businesses.list as jest.Mock).mockResolvedValue([
      {
        id: "b1",
        name: "Cafe",
        city: "Chennai",
        slug: "cafe",
        address: "12 MG Road",
        logo_url: "/uploads/cafe-logo.png",
        average_rating: 4,
        review_count: 1,
      },
    ]);
    (reviews.list as jest.Mock).mockResolvedValue([]);
  });

  it("does not intercept low star ratings", async () => {
    render(<CollectReviewPage params={resolvedParams({ businessId: "b1" })} />);
    expect(await screen.findByText(/Your review takes/i)).toBeInTheDocument();
    expect(await screen.findByText("Cafe")).toBeInTheDocument();
    expect(screen.getByText("12 MG Road, Chennai")).toBeInTheDocument();
    expect(screen.getByText("Cafe").closest("div")).toHaveStyle(
      "background-image: linear-gradient(to top, rgba(15,23,42,0.75), rgba(15,23,42,0.15)), url(http://localhost:8000/uploads/cafe-logo.png)",
    );
    clickStar(1);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(screen.getByPlaceholderText(/share what made your visit memorable/i)).toBeInTheDocument();
    expect(screen.queryByText(/google/i)).not.toBeInTheDocument();
  });

  it("creates the review through the existing API when signed in", async () => {
    (auth.me as jest.Mock).mockResolvedValue({ id: "c1", role: "customer" });
    (reviews.create as jest.Mock).mockResolvedValue({ id: "r1" });

    render(<CollectReviewPage params={resolvedParams({ businessId: "b1" })} />);
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
    const maps = screen.getByRole("link", { name: /share on google maps too/i });
    expect(maps).toHaveAttribute("href", expect.stringContaining("google.com/maps"));
  });

  it("redirects to login with next= when the visitor is not signed in", async () => {
    (auth.me as jest.Mock).mockRejectedValue(new Error("unauthorized"));

    render(<CollectReviewPage params={resolvedParams({ businessId: "b1" })} />);
    await screen.findByText("Cafe");
    clickStar(1);
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    fireEvent.change(screen.getByPlaceholderText(/share what made your visit memorable/i), {
      target: { value: "Too noisy near the street." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    await waitFor(() => expect(pushMock).toHaveBeenCalledWith("/login?next=/collect/b1"));
    expect(reviews.create).not.toHaveBeenCalled();
  });
});
