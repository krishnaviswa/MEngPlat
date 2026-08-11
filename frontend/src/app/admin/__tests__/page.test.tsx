import { render, screen } from "@testing-library/react";
import AdminPage from "@/app/admin/page";
import { auth, apiFetch } from "@/lib/api";

const replaceMock = jest.fn();
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../../lib/api", () => ({
  auth: { me: jest.fn() },
  apiFetch: jest.fn(),
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

const meMock = auth.me as jest.Mock;
const apiFetchMock = apiFetch as jest.Mock;

const STATS = {
  total_users: 12,
  total_businesses: 7,
  pending_businesses: 2,
  total_reviews: 40,
  reported_reviews: 1,
};

describe("Admin panel stat tiles (S-021 AC 1 / AC 4 / AC 9)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
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

  // AC 9: "Total users" stays non-interactive -- no drill-down is added.
  it("keeps 'Total users' as a static, non-interactive tile", async () => {
    render(<AdminPage />);

    expect(await screen.findByText("Total users")).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: /total users/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /total users/i })).not.toBeInTheDocument();
  });
});
