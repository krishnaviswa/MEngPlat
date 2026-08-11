import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import MerchantDashboardPage from "@/components/MerchantDashboard";
import { auth, businesses, dashboard } from "@/lib/api";
import type { Business } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn() },
  businesses: { mine: jest.fn() },
  dashboard: { merchant: jest.fn(), insights: jest.fn(), refreshInsights: jest.fn() },
  reviews: { reply: jest.fn() },
}));

const meMock = auth.me as jest.Mock;
const mineMock = businesses.mine as jest.Mock;
const merchantStatsMock = dashboard.merchant as jest.Mock;
const insightsMock = dashboard.insights as jest.Mock;

function makeBusiness(overrides: Partial<Business> = {}): Business {
  return {
    id: "biz-1",
    name: "Biz One",
    slug: "biz-one",
    address: "1 Main St",
    city: "Metropolis",
    average_rating: 4.5,
    review_count: 10,
    status: "approved",
    ...overrides,
  };
}

function makeStats(overrides: Record<string, unknown> = {}) {
  return {
    total_reviews: 10,
    average_rating: 4.5,
    recent_reviews: [],
    sentiment_breakdown: { positive: 5, neutral: 3, negative: 2 },
    ...overrides,
  };
}

describe("MerchantDashboard tile interactivity (S-022)", () => {
  beforeAll(() => {
    // jsdom doesn't implement scrollIntoView -- stub it on the prototype so
    // scrollToSection() doesn't throw. jest.fn() instances record `this` in
    // `mock.instances`, which lets tests assert *which* DOM node a given
    // click scrolled to.
    window.HTMLElement.prototype.scrollIntoView = jest.fn();
    // jsdom also doesn't implement ResizeObserver, which recharts'
    // <ResponsiveContainer> (rendered by the pre-existing Sentiment
    // breakdown <Charts> section) requires.
    (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };
  });

  beforeEach(() => {
    jest.clearAllMocks();
    (window.HTMLElement.prototype.scrollIntoView as jest.Mock).mockClear();
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch" });
    insightsMock.mockResolvedValue({});
  });

  // S-022 AC1 + AC2: "Total reviews" renders as a real <button> (not an inert
  // <div>) and clicking it scrolls to the existing "Recent reviews" section.
  it("renders 'Total reviews' as a button that scrolls to #recent-reviews on click", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    const totalReviewsBtn = await screen.findByRole("button", { name: /total reviews/i });
    expect(totalReviewsBtn.tagName).toBe("BUTTON");

    fireEvent.click(totalReviewsBtn);

    const scrollMock = window.HTMLElement.prototype.scrollIntoView as jest.Mock;
    await waitFor(() => expect(scrollMock).toHaveBeenCalledTimes(1));
    expect(scrollMock.mock.instances[0]).toBe(document.getElementById("recent-reviews"));
  });

  // S-022 AC1 + AC3: "Average rating" renders as a real <button> and clicking
  // it scrolls to the existing "Sentiment breakdown" chart section.
  it("renders 'Average rating' as a button that scrolls to #sentiment-breakdown on click", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    const avgRatingBtn = await screen.findByRole("button", { name: /average rating/i });
    expect(avgRatingBtn.tagName).toBe("BUTTON");

    fireEvent.click(avgRatingBtn);

    const scrollMock = window.HTMLElement.prototype.scrollIntoView as jest.Mock;
    await waitFor(() => expect(scrollMock).toHaveBeenCalledTimes(1));
    expect(scrollMock.mock.instances[0]).toBe(document.getElementById("sentiment-breakdown"));
  });

  // S-022 AC4 (approved branch): the "Status" tile is a real <a> that links
  // to the business's public profile when status is "approved".
  it("links the 'Status' tile to the public profile when the business is approved", async () => {
    const business = makeBusiness({ id: "biz-1", slug: "biz-one", status: "approved" });
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    const statusLink = await screen.findByRole("link", { name: /status/i });
    expect(statusLink.tagName).toBe("A");
    expect(statusLink).toHaveAttribute("href", "/businesses/biz-one");
  });

  // S-022 AC4 (actionable branch): the "Status" tile links to the edit page
  // for pending/rejected/suspended businesses instead of the public profile.
  it("links the 'Status' tile to the edit page when the business is pending", async () => {
    const business = makeBusiness({ id: "biz-2", slug: "biz-two", status: "pending" });
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    const statusLink = await screen.findByRole("link", { name: /status/i });
    expect(statusLink.tagName).toBe("A");
    expect(statusLink).toHaveAttribute("href", "/merchant/businesses/biz-2/edit");
  });

  // S-022 AC4 (actionable branch, suspended variant): same edit-page rule
  // applies to "suspended", not just "pending".
  it("links the 'Status' tile to the edit page when the business is suspended", async () => {
    const business = makeBusiness({ id: "biz-3", slug: "biz-three", status: "suspended" });
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    const statusLink = await screen.findByRole("link", { name: /status/i });
    expect(statusLink).toHaveAttribute("href", "/merchant/businesses/biz-3/edit");
  });

  // S-022 AC5: switching the "Your businesses" selector updates the Status
  // tile's href to the newly selected business -- no stale reference to the
  // previously selected one.
  it("updates the Status tile's href when the business selector changes", async () => {
    const approvedBiz = makeBusiness({ id: "biz-approved", slug: "biz-approved-slug", name: "Approved Biz", status: "approved" });
    const pendingBiz = makeBusiness({ id: "biz-pending", slug: "biz-pending-slug", name: "Pending Biz", status: "pending" });
    mineMock.mockResolvedValue([approvedBiz, pendingBiz]);
    merchantStatsMock.mockImplementation((id: string) =>
      Promise.resolve(makeStats({ total_reviews: id === approvedBiz.id ? 3 : 7 })),
    );

    render(<MerchantDashboardPage />);

    // Initially selected business is the first in the owned list (approved).
    let statusLink = await screen.findByRole("link", { name: /status/i });
    expect(statusLink).toHaveAttribute("href", "/businesses/biz-approved-slug");

    fireEvent.change(screen.getByRole("combobox"), { target: { value: pendingBiz.id } });

    await waitFor(() =>
      expect(merchantStatsMock).toHaveBeenCalledWith(pendingBiz.id),
    );
    statusLink = await screen.findByRole("link", { name: /status/i });
    await waitFor(() =>
      expect(statusLink).toHaveAttribute("href", "/merchant/businesses/biz-pending/edit"),
    );
  });

  // S-022 AC6: a business with zero reviews still renders the existing "No
  // reviews yet." empty state under the Total reviews tile's scroll target,
  // with no crash on click.
  it("shows the existing empty state under #recent-reviews and does not crash when clicked, for a business with zero reviews", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats({ total_reviews: 0, recent_reviews: [] }));

    render(<MerchantDashboardPage />);

    const totalReviewsBtn = await screen.findByRole("button", { name: /total reviews/i });
    expect(await screen.findByText("No reviews yet.")).toBeInTheDocument();
    expect(document.getElementById("recent-reviews")).toContainElement(screen.getByText("No reviews yet."));

    expect(() => fireEvent.click(totalReviewsBtn)).not.toThrow();
    const scrollMock = window.HTMLElement.prototype.scrollIntoView as jest.Mock;
    await waitFor(() => expect(scrollMock).toHaveBeenCalledTimes(1));
    expect(scrollMock.mock.instances[0]).toBe(document.getElementById("recent-reviews"));
  });
});
