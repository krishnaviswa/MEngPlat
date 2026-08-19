import { render, screen } from "@testing-library/react";
import { AdminBusinessReportsQueue } from "@/app/admin/business-reports/page";
import { businessReports } from "@/lib/api";

jest.mock("../../../../lib/api", () => ({
  businessReports: { adminList: jest.fn(), adminMessage: jest.fn(), adminUpdate: jest.fn() },
}));

const adminListMock = businessReports.adminList as jest.Mock;

describe("AdminBusinessReportsQueue (S-089)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("flags a shop as Repeat when is_repeat is true and shows the thread", async () => {
    adminListMock.mockResolvedValue([
      {
        id: "r1",
        business_id: "biz-1",
        business_name: "Corner Bakery",
        reason: "Spam listing that should be reviewed now.",
        status: "open",
        is_repeat: true,
        report_count: 3,
        messages: [{ id: "m1", body: "Also the phone number bounces.", created_at: "2026-08-19T00:00:00Z" }],
      },
    ]);

    render(<AdminBusinessReportsQueue />);

    expect(await screen.findByText("Corner Bakery")).toBeInTheDocument();
    expect(screen.getByText(/repeat \(3\)/i)).toBeInTheDocument();
    expect(screen.getByText(/also the phone number bounces/i)).toBeInTheDocument();
  });
});
