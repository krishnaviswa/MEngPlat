import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminPaymentPanel } from "@/components/admin/AdminPaymentPanel";
import { payments } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  payments: {
    listAdmin: jest.fn(),
    mockComplete: jest.fn(),
    approvePayment: jest.fn(),
    rejectPayment: jest.fn(),
    refundPayment: jest.fn(),
  },
}));

const listMock = payments.listAdmin as jest.Mock;
const approveMock = payments.approvePayment as jest.Mock;

describe("AdminPaymentPanel", () => {
  it("lists a payment and approves a captured boost", async () => {
    listMock
      .mockResolvedValueOnce([
        {
          id: "pay-1",
          status: "paid",
          amount_paise: 29900,
          currency: "INR",
          sku_code: "featured_7d",
          duration_days: 7,
          provider: "mock",
          provider_order_id: "order_1",
          created_at: "2026-08-15T00:00:00Z",
          approved_at: null,
          rejected_at: null,
          platform_fee_paise: 29200,
          gateway_fee_paise: 700,
          business_id: "b-1",
          business_name: "Cafe One",
          merchant_user_id: "m-1",
          merchant_email: "shop@example.com",
          merchant_name: "Shop Owner",
          merchant_payment_count: 2,
          awaiting_approval: true,
        },
      ])
      .mockResolvedValueOnce([]);
    approveMock.mockResolvedValue({
      id: "pay-1",
      approved_at: "2026-08-15T01:00:00Z",
      placement_id: "pl-1",
      ends_at: "2026-08-22T01:00:00Z",
    });

    render(<AdminPaymentPanel />);
    expect(await screen.findByText("Cafe One")).toBeInTheDocument();
    expect(screen.getByText(/2 payments/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: /approve boost/i }));
    await waitFor(() => expect(approveMock).toHaveBeenCalledWith("pay-1"));
  });
});
