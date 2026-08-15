import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { FeaturedBoostPanel } from "@/components/FeaturedBoostPanel";
import { payments } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  payments: { placement: jest.fn(), checkoutFeatured: jest.fn() },
}));

const placementMock = payments.placement as jest.Mock;
const checkoutMock = payments.checkoutFeatured as jest.Mock;

const SKUS = [
  { code: "featured_7d", duration_days: 7, listed_price_inr: 299, amount_paise: 29900 },
  { code: "featured_15d", duration_days: 15, listed_price_inr: 499, amount_paise: 49900 },
  { code: "featured_30d", duration_days: 30, listed_price_inr: 899, amount_paise: 89900 },
];

describe("FeaturedBoostPanel", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("disables boost copy when listing is not approved", async () => {
    placementMock.mockResolvedValue({
      business_id: "b1",
      active: false,
      placement: null,
      sku: SKUS[0],
      skus: SKUS,
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="pending" />);
    expect(await screen.findByText(/only after the listing is approved/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /boost this listing/i })).not.toBeInTheDocument();
  });

  it("shows three SKU tiles and paid-placement copy, not an AI score", async () => {
    placementMock.mockResolvedValue({
      business_id: "b1",
      active: false,
      placement: null,
      sku: SKUS[0],
      skus: SKUS,
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="approved" />);
    expect(await screen.findByText(/₹299 \/ 7 days/i)).toBeInTheDocument();
    expect(screen.getByText(/₹499 \/ 15 days/i)).toBeInTheDocument();
    expect(screen.getByText(/₹899 \/ 1 month/i)).toBeInTheDocument();
    expect(screen.getByText(/not an AI quality score/i)).toBeInTheDocument();
    expect(screen.queryByText(/grant|sponsorship/i)).not.toBeInTheDocument();
  });

  it("starts mock checkout without loading Razorpay and tells the merchant to wait for admin", async () => {
    placementMock.mockResolvedValue({
      business_id: "b1",
      active: false,
      placement: null,
      sku: SKUS[0],
      skus: SKUS,
    });
    checkoutMock.mockResolvedValue({
      payment_id: "pay1",
      provider: "mock",
      provider_order_id: "order_mock_abc",
      amount_paise: 29900,
      currency: "INR",
      sku: SKUS[0],
      checkout: { key_id: "", order_id: "order_mock_abc", amount: 29900, currency: "INR", name: "x", description: "y" },
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="approved" />);
    fireEvent.click(await screen.findByRole("button", { name: /₹299 \/ 7 days/i }));
    await waitFor(() => expect(checkoutMock).toHaveBeenCalledWith("b1", "featured_7d"));
    expect(await screen.findByText(/demo order/i)).toBeInTheDocument();
    expect(screen.getByText(/order_mock_abc/)).toBeInTheDocument();
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
      sku: SKUS[0],
      skus: SKUS,
    });
    render(<FeaturedBoostPanel businessId="b1" listingStatus="approved" />);
    expect(await screen.findByText(/Active until/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /boost this listing/i })).not.toBeInTheDocument();
  });
});
