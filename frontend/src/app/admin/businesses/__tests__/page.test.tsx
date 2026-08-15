import { Suspense } from "react";
import { render, screen } from "@testing-library/react";
import AdminBusinessDrilldownPage from "@/app/admin/businesses/[id]/page";
import { auth, businesses, payments, reviews } from "@/lib/api";
import type { Business, Review } from "@/lib/api";

const replaceMock = jest.fn();
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../../../lib/api", () => ({
  auth: { me: jest.fn() },
  businesses: { adminAll: jest.fn() },
  reviews: { adminAll: jest.fn() },
  payments: { placement: jest.fn(), disablePlacement: jest.fn(), refundPayment: jest.fn(), mockComplete: jest.fn() },
}));

const meMock = auth.me as jest.Mock;
const adminAllBusinessesMock = businesses.adminAll as jest.Mock;
const adminAllReviewsMock = reviews.adminAll as jest.Mock;
const placementMock = payments.placement as jest.Mock;

// The page reads its dynamic route param via React's `use(params)` on a
// Promise (Next.js 15's async-params client-component pattern). A bare
// `Promise.resolve(...)` genuinely never un-suspends inside jsdom + RTL in
// this project's React 19 setup (confirmed via a minimal repro: the
// Suspense boundary's ping is scheduled through the "scheduler" package's
// MessageChannel, which does not flush within jsdom/RTL's act() regardless
// of how many microtask/macrotask ticks are awaited). Pre-tagging the
// thenable as already "fulfilled" -- the same shape React itself writes
// onto a promise the first time `use()` reads it -- makes `use()` return
// synchronously and skip Suspense entirely, which is the documented escape
// hatch for testing this exact pattern.
function resolvedParams(value: { id: string }): Promise<{ id: string }> {
  return { status: "fulfilled", value, then() {} } as unknown as Promise<{ id: string }>;
}

function makeBusiness(overrides: Partial<Business> = {}): Business {
  return {
    id: "biz-1",
    name: "Corner Bakery",
    slug: "corner-bakery",
    address: "1 Main St",
    city: "Chennai",
    average_rating: 4.5,
    review_count: 2,
    status: "approved",
    ...overrides,
  };
}

function makeReview(overrides: Partial<Review> = {}): Review {
  return {
    id: "rev-1",
    business_id: "biz-1",
    rating: 5,
    body: "Wonderful bread and service.",
    like_count: 0,
    created_at: new Date().toISOString(),
    ...overrides,
  };
}

// S-021 AC 3 / AC 6: admin business drill-down shows shop name + full review
// history reached purely by database id (no slug), with a "No reviews yet"
// empty state when there are zero reviews.
describe("Admin business drill-down page (S-021)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
    placementMock.mockResolvedValue(null);
  });

  it("shows the business's shop name and its review history without needing a slug", async () => {
    adminAllBusinessesMock.mockResolvedValue([
      makeBusiness({ id: "biz-1", name: "Corner Bakery" }),
      makeBusiness({ id: "biz-2", name: "Other Biz" }),
    ]);
    adminAllReviewsMock.mockResolvedValue([makeReview()]);

    render(
      <Suspense fallback="loading-params">
        <AdminBusinessDrilldownPage params={resolvedParams({ id: "biz-1" })} />
      </Suspense>,
    );

    expect(await screen.findByRole("heading", { name: "Corner Bakery" })).toBeInTheDocument();
    expect(await screen.findByText("Wonderful bread and service.")).toBeInTheDocument();
    expect(adminAllReviewsMock).toHaveBeenCalledWith({ business_id: "biz-1" });
  });

  it("shows a 'No reviews yet' empty state for a business with zero reviews", async () => {
    adminAllBusinessesMock.mockResolvedValue([makeBusiness({ id: "biz-1", name: "Empty Shop" })]);
    adminAllReviewsMock.mockResolvedValue([]);

    render(
      <Suspense fallback="loading-params">
        <AdminBusinessDrilldownPage params={resolvedParams({ id: "biz-1" })} />
      </Suspense>,
    );

    expect(await screen.findByRole("heading", { name: "Empty Shop" })).toBeInTheDocument();
    expect(await screen.findByText("No reviews yet")).toBeInTheDocument();
    expect(screen.queryByText(/error/i)).not.toBeInTheDocument();
  });
});
