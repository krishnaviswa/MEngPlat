import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminSupportQueue } from "@/app/admin/support/page";
import { support } from "@/lib/api";

jest.mock("../../../../lib/api", () => ({
  support: { adminTickets: jest.fn(), updateTicket: jest.fn() },
}));

const adminTicketsMock = support.adminTickets as jest.Mock;
const updateTicketMock = support.updateTicket as jest.Mock;

describe("AdminSupportQueue (S-088)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("lists tickets and lets admin set status with a response", async () => {
    adminTicketsMock.mockResolvedValue([
      {
        id: "t1",
        name: "Ann",
        phone: "+919876543210",
        issue: "I cannot find my review after submitting it.",
        status: "open",
        admin_response: null,
      },
    ]);
    updateTicketMock.mockResolvedValue({
      id: "t1",
      name: "Ann",
      phone: "+919876543210",
      issue: "I cannot find my review after submitting it.",
      status: "resolved",
      admin_response: "Found and restored.",
    });

    render(<AdminSupportQueue />);

    expect(await screen.findByText(/ann · \+919876543210 · open/i)).toBeInTheDocument();
    fireEvent.change(screen.getByPlaceholderText(/response to the customer/i), {
      target: { value: "Found and restored." },
    });
    fireEvent.click(screen.getByRole("button", { name: /mark resolved/i }));

    await waitFor(() =>
      expect(updateTicketMock).toHaveBeenCalledWith("t1", {
        status: "resolved",
        admin_response: "Found and restored.",
      }),
    );
    expect(await screen.findByText(/ann · \+919876543210 · resolved/i)).toBeInTheDocument();
  });
});
