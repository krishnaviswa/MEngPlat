import { render, screen } from "@testing-library/react";
import { FeaturedBoostPanel } from "@/components/FeaturedBoostPanel";
import { payments } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  payments: { placement: jest.fn(), checkoutFeatured: jest.fn() },
}));

const placementMock = payments.placement as jest.Mock;

describe("FeaturedBoostPanel", () => {
  it("disables boost copy when listing is not approved", async () => {
    placementMock.mockResolvedValue({
      business_id: "b1",
      active: false,
      placement: null,
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="pending" />);
    expect(await screen.findByText(/only after the listing is approved/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /boost this listing/i })).not.toBeInTheDocument();
  });

  it("shows expiry when placement is active", async () => {
    placementMock.mockResolvedValue({
      business_id: "b1",
      active: true,
      placement: {
        id: "p1",
        starts_at: "2026-08-15T00:00:00Z",
        ends_at: "2026-08-22T00:00:00Z",
        disabled_at: null,
        payment_id: "pay1",
      },
      sku: { code: "featured_7d", duration_days: 7, listed_price_inr: 499 },
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="approved" />);
    expect(await screen.findByText(/Active until/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /boost this listing/i })).not.toBeInTheDocument();
  });
});
