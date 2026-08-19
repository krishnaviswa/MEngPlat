import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { SupportTicketForm } from "@/components/SupportTicketForm";
import { businessReports, support } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  support: { createTicket: jest.fn(), myTickets: jest.fn() },
  businessReports: { mine: jest.fn() },
}));

const createTicketMock = support.createTicket as jest.Mock;
const myTicketsMock = support.myTickets as jest.Mock;
const mineReportsMock = businessReports.mine as jest.Mock;

describe("SupportTicketForm (S-088)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  it("submits name, phone, and issue without requiring a login", async () => {
    createTicketMock.mockResolvedValue({
      id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      status: "open",
      issue: "I cannot find my review after submitting it.",
      admin_response: null,
    });

    render(<SupportTicketForm />);

    fireEvent.change(screen.getByRole("textbox", { name: /^name$/i }), { target: { value: "Guest Person" } });
    fireEvent.change(screen.getByRole("textbox", { name: /^phone$/i }), { target: { value: "+919876543210" } });
    fireEvent.change(screen.getByRole("textbox", { name: /^issue$/i }), {
      target: { value: "I cannot find my review after submitting it." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit/i }));

    await waitFor(() => expect(createTicketMock).toHaveBeenCalledTimes(1));
    expect(createTicketMock).toHaveBeenCalledWith({
      name: "Guest Person",
      phone: "+919876543210",
      issue: "I cannot find my review after submitting it.",
    });
    expect(await screen.findByText(/ticket submitted \(open\)/i)).toBeInTheDocument();
    expect(myTicketsMock).not.toHaveBeenCalled();
  });

  it("omits business_id when the optional field is blank and includes it when filled", async () => {
    createTicketMock.mockResolvedValue({
      id: "11111111-1111-1111-1111-111111111111",
      status: "open",
      issue: "Hours are wrong on the listing page.",
      admin_response: null,
    });

    render(<SupportTicketForm />);
    fireEvent.change(screen.getByRole("textbox", { name: /^name$/i }), { target: { value: "Ann" } });
    fireEvent.change(screen.getByRole("textbox", { name: /^phone$/i }), { target: { value: "+919876543210" } });
    fireEvent.change(screen.getByRole("textbox", { name: /^issue$/i }), {
      target: { value: "Hours are wrong on the listing page." },
    });
    fireEvent.change(screen.getByRole("textbox", { name: /related business id/i }), {
      target: { value: "  biz-uuid-1  " },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit/i }));

    await waitFor(() =>
      expect(createTicketMock).toHaveBeenCalledWith(
        expect.objectContaining({ business_id: "biz-uuid-1" }),
      ),
    );
  });

  it("loads previous tickets with status and admin response when signed in", async () => {
    localStorage.setItem("access_token", "tok-1");
    myTicketsMock.mockResolvedValue([
      {
        id: "t1",
        status: "in_progress",
        issue: "Payment receipt missing from my account.",
        admin_response: "We emailed a copy.",
      },
    ]);
    mineReportsMock.mockResolvedValue([]);

    render(<SupportTicketForm />);

    expect(await screen.findByText("Your tickets")).toBeInTheDocument();
    expect(screen.getByText("in progress")).toBeInTheDocument();
    expect(screen.getByText("Payment receipt missing from my account.")).toBeInTheDocument();
    expect(screen.getByText("Admin: We emailed a copy.")).toBeInTheDocument();
    expect(screen.getByText("No shop reports yet.")).toBeInTheDocument();
  });
});
