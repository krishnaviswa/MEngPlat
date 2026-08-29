import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import PartnerConsolePage from "@/app/dev/partner-console/page";

jest.mock("../../../../lib/api", () => ({
  businesses: { list: jest.fn() },
  partnerMock: { dispatch: jest.fn(), requests: jest.fn(), callbacks: jest.fn() },
}));
jest.mock("../../../../lib/featureFlags", () => ({ isPartnerMockEnabled: jest.fn() }));

import { businesses, partnerMock } from "@/lib/api";
import { isPartnerMockEnabled } from "@/lib/featureFlags";

const listMock = businesses.list as jest.Mock;
const dispatchMock = partnerMock.dispatch as jest.Mock;
const requestsMock = partnerMock.requests as jest.Mock;
const callbacksMock = partnerMock.callbacks as jest.Mock;
const flagMock = isPartnerMockEnabled as jest.Mock;

describe("Mock partner console (S-123)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    requestsMock.mockResolvedValue([]);
    callbacksMock.mockResolvedValue([]);
    listMock.mockResolvedValue([
      { id: "b1", name: "Sri Balaji Tiffin", slug: "sri-balaji", city: "Chennai", average_rating: 4, review_count: 3 },
    ]);
  });

  it("shows an off state when the flag is disabled", () => {
    flagMock.mockReturnValue(false);
    render(<PartnerConsolePage />);
    expect(screen.getByText(/mock partner console is off/i)).toBeInTheDocument();
  });

  it("dispatches through the mock endpoint and shows the customer message + link", async () => {
    flagMock.mockReturnValue(true);
    dispatchMock.mockResolvedValue({
      collect_url: "http://localhost:3000/c/tok123",
      token: "tok123",
      review_request_id: "rq1",
      message: "Thanks for shopping at Sri Balaji Tiffin. Rate your visit (30 sec, no login): http://localhost:3000/c/tok123",
    });
    render(<PartnerConsolePage />);

    await waitFor(() => expect(screen.getByRole("option", { name: /Sri Balaji Tiffin/ })).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: /send review request/i }));

    await waitFor(() => expect(dispatchMock).toHaveBeenCalledWith(expect.objectContaining({ business_slug: "sri-balaji" })));
    expect(await screen.findByText(/Rate your visit/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /c\/tok123/ })).toBeInTheDocument();
  });

  it("renders callbacks received from MerchantHub", async () => {
    flagMock.mockReturnValue(true);
    callbacksMock.mockResolvedValue([
      {
        received_at: new Date().toISOString(),
        signature: "sha256=deadbeef",
        event: { event: "review.captured", status: "published", rating: 5 },
      },
    ]);
    render(<PartnerConsolePage />);

    expect(await screen.findByText("review.captured")).toBeInTheDocument();
    expect(screen.getByText(/sha256=deadbeef/)).toBeInTheDocument();
  });
});
