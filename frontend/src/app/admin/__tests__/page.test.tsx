import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import AdminPage from "@/app/admin/page";
import { auth, apiFetch, dashboard } from "@/lib/api";

const replaceMock = jest.fn();
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../../lib/api", () => ({
  auth: { me: jest.fn() },
  apiFetch: jest.fn(),
  // S-034 added a "Platform trends" chart row that calls dashboard.adminSeries()
  // on mount; without this the page's useEffect throws synchronously in every
  // test ("Cannot read properties of undefined") since the mocked module had
  // no `dashboard` export.
  dashboard: { adminSeries: jest.fn().mockResolvedValue({ granularity: "day", days: 90, series: {} }) },
}));

// PendingBusinessQueue / ReportedReviewsQueue each do their own fetching on
// mount via the real `businesses`/`reviews` api client, which this file does
// not mock -- stub the components themselves so the page test stays focused
// on the stat tiles (AC 1 / AC 4 / AC 9), matching MerchantDashboard.test.tsx's
// scope-narrowing approach for that page's own sections.
jest.mock("../../../components/admin/PendingBusinessQueue", () => ({
  PendingBusinessQueue: () => <div>pending-queue-stub</div>,
}));
jest.mock("../../../components/admin/ReportedReviewsQueue", () => ({
  ReportedReviewsQueue: () => <div>reported-queue-stub</div>,
}));
jest.mock("../../../components/admin/AdminPaymentPanel", () => ({
  AdminPaymentPanel: () => <div>payments-stub</div>,
}));

const meMock = auth.me as jest.Mock;
const apiFetchMock = apiFetch as jest.Mock;
const adminSeriesMock = dashboard.adminSeries as jest.Mock;

const STATS = {
  total_users: 12,
  total_businesses: 7,
  pending_businesses: 2,
  total_reviews: 40,
  reported_reviews: 1,
  open_support_tickets: 4,
  repeat_shop_reports: 2,
  processing_businesses: 3,
};

describe("Admin panel stat tiles (S-021 AC 1 / AC 4; S-034 AC 4 / AC 6)", () => {
  beforeAll(() => {
    // jsdom doesn't implement scrollIntoView -- stub it on the prototype so
    // scrollToSection() doesn't throw (same pattern as MerchantDashboard.test.tsx).
    window.HTMLElement.prototype.scrollIntoView = jest.fn();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    (window.HTMLElement.prototype.scrollIntoView as jest.Mock).mockClear();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    apiFetchMock.mockResolvedValue(STATS);
  });

  // AC 1: "Total businesses" navigates to the All businesses browse view.
  it("renders 'Total businesses' as a link to /admin/businesses", async () => {
    render(<AdminPage />);

    const link = await screen.findByRole("link", { name: /total businesses/i });
    expect(link).toHaveAttribute("href", "/admin/businesses");
  });

  // AC 4: "Total reviews" navigates to the All reviews browse view.
  it("renders 'Total reviews' as a link to /admin/reviews", async () => {
    render(<AdminPage />);

    const link = await screen.findByRole("link", { name: /total reviews/i });
    expect(link).toHaveAttribute("href", "/admin/reviews");
  });

  // S-034 AC 4/AC 6 (UX notes): "Total users" now doors into the user-admin
  // panel instead of staying static -- this intentionally supersedes S-021
  // AC 9's "static, non-interactive tile" behavior (see S-034 slice UX notes
  // and Builder changelog). Mirrors the click-to-scroll pattern already
  // asserted for the pending_businesses / reported_reviews tiles below.
  it("renders 'Total users' as a button that scrolls to #admin-users", async () => {
    render(<AdminPage />);

    const button = await screen.findByRole("button", { name: /total users/i });
    expect(button.tagName).toBe("BUTTON");

    fireEvent.click(button);
    const scrollMock = window.HTMLElement.prototype.scrollIntoView as jest.Mock;
    await waitFor(() => expect(scrollMock).toHaveBeenCalledTimes(1));
    expect(scrollMock.mock.instances[0]).toBe(document.getElementById("admin-users"));
  });

  it("renders open support tickets and repeat shop reports as drill-down links", async () => {
    render(<AdminPage />);

    const tickets = await screen.findByRole("link", { name: /open support tickets/i });
    expect(tickets).toHaveAttribute("href", "/admin/support");
    expect(screen.getByRole("link", { name: /repeat shop reports/i })).toHaveAttribute(
      "href",
      "/admin/business-reports",
    );
  });

  it("renders processing businesses as a button that scrolls to the approval queue", async () => {
    render(<AdminPage />);

    const button = await screen.findByRole("button", { name: /processing businesses/i });
    fireEvent.click(button);
    const scrollMock = window.HTMLElement.prototype.scrollIntoView as jest.Mock;
    await waitFor(() => expect(scrollMock).toHaveBeenCalled());
    expect(scrollMock.mock.instances.at(-1)).toBe(document.getElementById("pending-businesses"));
  });
});

describe("Platform trends chart row (S-034 AC 1 / AC 8)", () => {
  beforeAll(() => {
    // jsdom doesn't implement ResizeObserver, which recharts' <ResponsiveContainer>
    // (rendered for any non-all-zero series) requires.
    (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };
  });

  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    apiFetchMock.mockResolvedValue(STATS);
  });

  // AC 8: a brand-new platform (all buckets zero across all four series)
  // renders the dashed empty-chart state, not a Recharts crash or blank error.
  it("shows a dashed empty-chart state when every series bucket is zero", async () => {
    adminSeriesMock.mockResolvedValue({
      granularity: "day",
      days: 90,
      series: {
        new_users: [{ bucket: "2026-08-14", count: 0 }],
        businesses_approved: [{ bucket: "2026-08-14", count: 0 }],
        new_reviews: [{ bucket: "2026-08-14", count: 0 }],
        new_reports: [{ bucket: "2026-08-14", count: 0 }],
      },
    });

    render(<AdminPage />);

    expect(await screen.findByText("Platform trends")).toBeInTheDocument();
    const emptyBoxes = await screen.findAllByText("No data yet for this window");
    expect(emptyBoxes).toHaveLength(4);
  });

  // AC 1: real (non-zero) bucket data renders as a chart, not the empty state --
  // proving new_users/businesses_approved/new_reviews/new_reports are wired to real data.
  it("does not show the empty-chart state when a series has non-zero data", async () => {
    adminSeriesMock.mockResolvedValue({
      granularity: "day",
      days: 90,
      series: {
        new_users: [{ bucket: "2026-08-14", count: 3 }],
        businesses_approved: [{ bucket: "2026-08-14", count: 0 }],
        new_reviews: [{ bucket: "2026-08-14", count: 0 }],
        new_reports: [{ bucket: "2026-08-14", count: 0 }],
      },
    });

    render(<AdminPage />);

    expect(await screen.findByText("New users")).toBeInTheDocument();
    // Only the 3 all-zero series fall back to the dashed empty box.
    const emptyBoxes = await screen.findAllByText("No data yet for this window");
    expect(emptyBoxes).toHaveLength(3);
  });
});

describe("Section order (S-082 AC1)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    apiFetchMock.mockResolvedValue(STATS);
    adminSeriesMock.mockResolvedValue({ granularity: "day", days: 90, series: {} });
  });

  // AC1: Categories renders immediately after the stats/trends area and before
  // Pending businesses, Reported reviews, WhatsApp updates, Payments, Users.
  it("renders Categories before Pending businesses / Reported reviews / WhatsApp updates / Payments / Users", async () => {
    render(<AdminPage />);

    await screen.findByRole("heading", { name: "Categories" });
    const headings = screen
      .getAllByRole("heading", { level: 2 })
      .map((h) => h.textContent);

    expect(headings).toEqual([
      "Categories",
      "Pending businesses",
      "Reported reviews",
      "Support",
      "WhatsApp updates",
      "Payments",
      "Users",
    ]);
  });
});

describe("Ops nav (S-090 AC1)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    apiFetchMock.mockResolvedValue(STATS);
    adminSeriesMock.mockResolvedValue({ granularity: "day", days: 90, series: {} });
  });

  it("renders the operations nav on the landing page", async () => {
    render(<AdminPage />);

    await screen.findByRole("navigation", { name: "Admin operations" });
    expect(screen.getByRole("link", { name: "Support tickets" })).toHaveAttribute("href", "/admin/support");
    expect(screen.getByRole("link", { name: "Shop reports" })).toHaveAttribute("href", "/admin/business-reports");
  });
});

describe("Support block (S-087 AC3)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    apiFetchMock.mockResolvedValue(STATS);
    adminSeriesMock.mockResolvedValue({ granularity: "day", days: 90, series: {} });
  });

  it("shows support email plus links to tickets, shop reports, and public /support", async () => {
    render(<AdminPage />);

    expect(await screen.findByRole("heading", { name: "Support" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "support@merchanthub.example" })).toHaveAttribute(
      "href",
      "mailto:support@merchanthub.example",
    );
    expect(screen.getByRole("link", { name: "Support tickets →" })).toHaveAttribute("href", "/admin/support");
    expect(screen.getByRole("link", { name: "Shop reports →" })).toHaveAttribute("href", "/admin/business-reports");
    expect(screen.getByRole("link", { name: /public contact page/i })).toHaveAttribute("href", "/support");
    expect(screen.getByRole("heading", { name: "Reported reviews" })).toBeInTheDocument();
    expect(screen.getByText("reported-queue-stub")).toBeInTheDocument();
  });
});
