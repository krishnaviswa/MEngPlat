import { render, screen } from "@testing-library/react";
import SupportPage from "@/app/support/page";

jest.mock("../../../components/SupportTicketForm", () => ({
  SupportTicketForm: () => <div>ticket-form-stub</div>,
}));

describe("Support page (S-087)", () => {
  it("shows the published support email and explains a query can be submitted", async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ email: "support@merchanthub.example", support_path: "/support" }),
    }) as jest.Mock;

    const ui = await SupportPage();
    render(ui);

    const mail = screen.getByRole("link", { name: "support@merchanthub.example" });
    expect(mail).toHaveAttribute("href", "mailto:support@merchanthub.example");
    expect(screen.getByText(/send a query below/i)).toBeInTheDocument();
    expect(screen.getByText("ticket-form-stub")).toBeInTheDocument();
  });
});
