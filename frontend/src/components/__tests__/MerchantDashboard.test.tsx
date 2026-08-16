import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import MerchantDashboardPage from "@/components/MerchantDashboard";
import { auth, businesses, dashboard, payments } from "@/lib/api";
import type { Business } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { me: jest.fn(), updateMe: jest.fn() },
  businesses: { mine: jest.fn() },
  dashboard: {
    merchant: jest.fn(),
    insights: jest.fn(),
    topics: jest.fn(),
    refreshInsights: jest.fn(),
    reviewsCsv: jest.fn(),
    benchmark: jest.fn(),
    getGoogleReviewsStatus: jest.fn(),
    searchGooglePlaces: jest.fn(),
    linkGooglePlace: jest.fn(),
    syncGoogleReviews: jest.fn(),
  },
  reviews: { reply: jest.fn() },
  payments: { placement: jest.fn(), checkoutFeatured: jest.fn() },
}));

const meMock = auth.me as jest.Mock;
const mineMock = businesses.mine as jest.Mock;
const merchantStatsMock = dashboard.merchant as jest.Mock;
const insightsMock = dashboard.insights as jest.Mock;
const topicsMock = dashboard.topics as jest.Mock;
const reviewsCsvMock = dashboard.reviewsCsv as jest.Mock;
const placementMock = payments.placement as jest.Mock;
const benchmarkMock = dashboard.benchmark as jest.Mock;
const googleReviewsStatusMock = dashboard.getGoogleReviewsStatus as jest.Mock;
// Unlinked by default (S-048) -- individual tests override when the Google
// reviews card's linked/synced states matter to them.
googleReviewsStatusMock.mockResolvedValue({ linked: false, place_id: null, review_count: 0, last_synced_at: null });

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
    topicsMock.mockResolvedValue(null);
    placementMock.mockResolvedValue({
      business_id: "biz-1",
      active: false,
      placement: null,
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
    benchmarkMock.mockResolvedValue({
      own_rating: 4.5,
      category_median: null,
      city_median: null,
      disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
    });
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

    // S-033 added a second combobox (date-range picker) to the same page, so
    // the plain `getByRole("combobox")` this test used before S-033 is now
    // ambiguous -- scope to the "Your businesses" selector by its label.
    fireEvent.change(screen.getByRole("combobox", { name: /your businesses/i }), {
      target: { value: pendingBiz.id },
    });

    // S-033 added a `{ range }` second argument to dashboard.merchant(); the
    // default range is "all" until the user picks a date-range option.
    await waitFor(() =>
      expect(merchantStatsMock).toHaveBeenCalledWith(pendingBiz.id, { range: "all" }),
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

describe("MerchantDashboard analytics (S-033)", () => {
  beforeAll(() => {
    window.HTMLElement.prototype.scrollIntoView = jest.fn();
    (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };
    // jsdom doesn't implement these; the Export CSV handler calls them.
    (URL as unknown as { createObjectURL: unknown }).createObjectURL = jest.fn(() => "blob:mock");
    (URL as unknown as { revokeObjectURL: unknown }).revokeObjectURL = jest.fn();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch" });
    insightsMock.mockResolvedValue({});
    topicsMock.mockResolvedValue(null);
    placementMock.mockResolvedValue({
      business_id: "biz-1",
      active: false,
      placement: null,
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
    benchmarkMock.mockResolvedValue({
      own_rating: 4.5,
      category_median: null,
      city_median: null,
      disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
    });
  });

  // AC 1 / AC 2: review_volume_by_month and rating_distribution render as
  // real chart data (not left as unused payload / not a canned AI series).
  it("charts DB review volume and rating mix from the dashboard payload", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        review_volume_by_month: [{ month: "2026-07", count: 4 }],
        rating_distribution: { "1": 0, "2": 0, "3": 1, "4": 2, "5": 3 },
      }),
    );

    render(<MerchantDashboardPage />);

    expect(await screen.findByText("Review volume")).toBeInTheDocument();
    expect(await screen.findByText("Rating mix (1-5 stars)")).toBeInTheDocument();
    // Charts render an SVG bar chart when data is non-empty (not the emptyMessage copy).
    expect(screen.queryByText("No reviews in this range yet.")).not.toBeInTheDocument();
  });

  // AC 3: changing the date-range selector refetches volume/mix/reply-rate
  // for the newly selected range (not values invented in AI JSON).
  it("refetches dashboard stats with the newly selected range", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);
    await waitFor(() => expect(merchantStatsMock).toHaveBeenCalledWith(business.id, { range: "all" }));

    fireEvent.change(screen.getByRole("combobox", { name: /date range/i }), { target: { value: "30" } });

    await waitFor(() => expect(merchantStatsMock).toHaveBeenCalledWith(business.id, { range: "30" }));
  });

  // AC 5: zero reviews in range -> reply_rate is null, rendered as "--" copy,
  // never a misleading "0%" as if reviews existed.
  it("shows '—' (not 0%) for reply rate when reply_rate is null", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats({ reply_rate: null }));

    render(<MerchantDashboardPage />);

    expect(await screen.findByText("Reply rate")).toBeInTheDocument();
    expect(screen.getByText("Reply rate").closest(".rounded-xl")).toHaveTextContent("—");
    expect(screen.queryByText("0%")).not.toBeInTheDocument();
  });

  // AC 5: a real reply_rate renders as a rounded percentage.
  it("renders reply_rate as a rounded percentage when reviews exist in range", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats({ reply_rate: 0.5 }));

    render(<MerchantDashboardPage />);

    expect(await screen.findByText("50%")).toBeInTheDocument();
  });

  // AC 8: empty range (zero in-range reviews) shows beginner-friendly copy,
  // not a crash or a fake series.
  it("shows empty-range copy when rating_distribution has zero reviews", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        review_volume_by_month: [],
        rating_distribution: { "1": 0, "2": 0, "3": 0, "4": 0, "5": 0 },
        reply_rate: null,
      }),
    );

    render(<MerchantDashboardPage />);

    expect(
      await screen.findByText(/no reviews in this range yet\. try a wider date range/i),
    ).toBeInTheDocument();
  });

  // AC 6: Export CSV downloads a blob for *this* business and the currently selected range.
  it("exports CSV for the selected business and range on click", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());
    reviewsCsvMock.mockResolvedValue(new Blob(["id,rating\n"], { type: "text/csv" }));

    render(<MerchantDashboardPage />);
    await screen.findByRole("button", { name: /export csv/i });

    fireEvent.click(screen.getByRole("button", { name: /export csv/i }));

    await waitFor(() => expect(reviewsCsvMock).toHaveBeenCalledWith(business.id, { range: "all" }));
  });

  // AC 4: AI monthly_trends always carry suggestion language and are
  // additionally flagged when degraded/mock -- never charted as DB fact.
  it("labels AI monthly_trends as a suggestion and flags degraded data", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());
    insightsMock.mockResolvedValue({
      degraded: true,
      monthly_trends: [{ month: "2026-06", positive: 2, neutral: 1, negative: 0 }],
    });

    render(<MerchantDashboardPage />);

    expect(await screen.findByText(/mock\/degraded data/i)).toBeInTheDocument();
    expect(screen.getByText(/not computed from your review history/i)).toBeInTheDocument();
    expect(screen.getByText(/\(suggestion\)/i)).toBeInTheDocument();
  });

  it("hosts the featured boost panel with paid-placement copy, not grants", async () => {
    mineMock.mockResolvedValue([makeBusiness({ status: "approved" })]);
    merchantStatsMock.mockResolvedValue(makeStats());

    render(<MerchantDashboardPage />);

    expect(await screen.findByText("Featured listing boost")).toBeInTheDocument();
    expect(screen.getByText(/not an AI quality score/i)).toBeInTheDocument();
    expect(screen.getByText(/₹299 \/ 7 days/i)).toBeInTheDocument();
    expect(screen.queryByText(/grant|sponsorship/i)).not.toBeInTheDocument();
  });
});

describe("MerchantDashboard chart upgrade + deltas (S-037)", () => {
  beforeAll(() => {
    window.HTMLElement.prototype.scrollIntoView = jest.fn();
    (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };
  });

  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch" });
    insightsMock.mockResolvedValue({});
    topicsMock.mockResolvedValue(null);
    placementMock.mockResolvedValue({
      business_id: "biz-1",
      active: false,
      placement: null,
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
    benchmarkMock.mockResolvedValue({
      own_rating: 4.5,
      category_median: null,
      city_median: null,
      disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
    });
  });

  it("renders review volume as an area chart (not bars)", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        review_volume_by_month: [{ month: "2026-07", count: 4 }],
        rating_distribution: { "1": 0, "2": 0, "3": 0, "4": 0, "5": 4 },
      }),
    );

    const { container } = render(<MerchantDashboardPage />);
    expect(await screen.findByText("Review volume")).toBeInTheDocument();
    await waitFor(() => {
      expect(container.querySelector('[data-chart-variant="area"]')).toBeTruthy();
    });
    expect(container.querySelectorAll('[data-chart-variant="bar"]').length).toBeGreaterThan(0);
  });

  it("hides period deltas on the all-time range (n/a, never a fake 0%)", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        reply_rate: 0.5,
        reply_rate_previous: null,
        review_count_in_range: 10,
        review_count_previous: null,
      }),
    );

    render(<MerchantDashboardPage />);
    expect(await screen.findByText("Reviews in range")).toBeInTheDocument();
    expect(screen.getByText("Reviews in range").closest(".rounded-xl")).toHaveTextContent("n/a");
    expect(screen.queryByText("0% vs prior period")).not.toBeInTheDocument();
  });

  it("shows n/a when the previous window has zero reviews", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        reply_rate: 0.4,
        reply_rate_previous: 0,
        review_count_in_range: 8,
        review_count_previous: 0,
      }),
    );

    render(<MerchantDashboardPage />);
    await screen.findByRole("combobox", { name: /date range/i });
    fireEvent.change(screen.getByRole("combobox", { name: /date range/i }), { target: { value: "30" } });
    expect(await screen.findByText("Reviews in range")).toBeInTheDocument();
    expect(screen.getByText("Reviews in range").closest(".rounded-xl")).toHaveTextContent("n/a");
  });

  it("shows a percent vs the prior 30-day window when previous counts exist", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(
      makeStats({
        reply_rate: 0.6,
        reply_rate_previous: 0.4,
        review_count_in_range: 12,
        review_count_previous: 8,
      }),
    );

    render(<MerchantDashboardPage />);
    fireEvent.change(await screen.findByRole("combobox", { name: /date range/i }), { target: { value: "30" } });
    expect(await screen.findByText("Last 30 days · +50% vs prior period")).toBeInTheDocument();
    expect(screen.getByText("+50% vs prior period")).toBeInTheDocument();
  });
});

describe("MerchantDashboard benchmark + collect QR (S-038 / S-040)", () => {
  beforeAll(() => {
    window.HTMLElement.prototype.scrollIntoView = jest.fn();
    (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };
  });

  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "u1", role: "merchant", full_name: "Merch" });
    insightsMock.mockResolvedValue({});
    topicsMock.mockResolvedValue(null);
    placementMock.mockResolvedValue({
      business_id: "biz-1",
      active: false,
      placement: null,
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
  });

  it("renders directory-median disclaimer from the benchmark payload", async () => {
    const business = makeBusiness();
    mineMock.mockResolvedValue([business]);
    merchantStatsMock.mockResolvedValue(makeStats());
    benchmarkMock.mockResolvedValue({
      own_rating: 4.5,
      category_median: null,
      city_median: 4.0,
      disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
    });

    render(<MerchantDashboardPage />);
    expect(
      await screen.findByText("Directory medians from MerchantHub listings — not an AI judgment."),
    ).toBeInTheDocument();
    expect(screen.getByText("Not enough nearby listings yet.")).toBeInTheDocument();
    expect(screen.queryByText(/AI judged/i)).not.toBeInTheDocument();
  });

  it("shows the collect QR on an approved listing and hides it when pending", async () => {
    const approved = makeBusiness({ id: "biz-ok", slug: "ok", status: "approved" });
    mineMock.mockResolvedValue([approved]);
    merchantStatsMock.mockResolvedValue(makeStats());
    benchmarkMock.mockResolvedValue({
      own_rating: 4.5,
      category_median: null,
      city_median: null,
      disclaimer: "Directory medians from MerchantHub listings — not an AI judgment.",
    });

    const { unmount } = render(<MerchantDashboardPage />);
    expect(await screen.findByText("Review collection QR")).toBeInTheDocument();
    expect(screen.getByText(`${window.location.origin}/collect/biz-ok`)).toBeInTheDocument();
    unmount();

    const pending = makeBusiness({ id: "biz-pend", slug: "pend", status: "pending" });
    mineMock.mockResolvedValue([pending]);
    render(<MerchantDashboardPage />);
    await screen.findByText("Awaiting approval");
    expect(screen.queryByText("Review collection QR")).not.toBeInTheDocument();
  });
});
