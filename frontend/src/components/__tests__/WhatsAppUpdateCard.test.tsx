import { render, screen } from "@testing-library/react";
import { WhatsAppUpdateCard } from "@/components/WhatsAppUpdateCard";
import { dashboard } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  dashboard: { createWhatsAppLink: jest.fn() },
}));

const createLink = dashboard.createWhatsAppLink as jest.Mock;

describe("WhatsAppUpdateCard (S-050)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("shows QR and wa.me URL for an available mock link", async () => {
    createLink.mockResolvedValue({
      available: true,
      wa_url: "https://wa.me/15551234567?text=MH-DEADBEEF",
      token: "MH-DEADBEEF",
      expires_at: "2026-08-17T00:00:00Z",
      display_number: "15551234567",
    });
    render(<WhatsAppUpdateCard businessId="biz-1" businessName="Joe's Cafe" />);
    expect(await screen.findByText("https://wa.me/15551234567?text=MH-DEADBEEF")).toBeInTheDocument();
    expect(screen.getByText(/wait for your approval/i)).toBeInTheDocument();
    expect(document.querySelector("svg")).toBeTruthy();
    expect(screen.getByRole("button", { name: /print for shop/i })).toBeInTheDocument();
  });

  it("shows an unavailable empty state when WhatsApp is not configured", async () => {
    createLink.mockResolvedValue({
      available: false,
      wa_url: null,
      token: null,
      expires_at: null,
      display_number: null,
    });
    render(<WhatsAppUpdateCard businessId="biz-1" />);
    // S-078: clarified copy -- this is a platform config gap, not something an
    // in-app admin action can fix.
    expect(await screen.findByText(/needs a one-time configuration change/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /print for shop/i })).not.toBeInTheDocument();
  });
});
