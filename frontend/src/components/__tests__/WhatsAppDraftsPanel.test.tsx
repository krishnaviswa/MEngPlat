import { render, screen, waitFor } from "@testing-library/react";
import { WhatsAppDraftsPanel } from "@/components/WhatsAppDraftsPanel";
import { dashboard } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  dashboard: {
    listWhatsAppDrafts: jest.fn(),
  },
}));

const listDrafts = dashboard.listWhatsAppDrafts as jest.Mock;

const sampleDraft = {
  id: "draft-1",
  source: "whatsapp",
  extracted_fields: { description: "Open 9-9 near the bus stand", address: "Near the bus stand" },
  status: "pending" as const,
  degraded: false,
  created_at: "2026-08-16T00:00:00Z",
};

describe("WhatsAppDraftsPanel (S-053, read-only)", () => {
  beforeEach(() => {
    listDrafts.mockReset();
  });

  it("renders nothing when there are no drafts", async () => {
    listDrafts.mockResolvedValue([]);
    const { container } = render(<WhatsAppDraftsPanel businessId="biz-1" />);
    await waitFor(() => expect(listDrafts).toHaveBeenCalled());
    expect(container.querySelector("section")).toBeNull();
  });

  it("labels extracted fields as suggestions and shows a pending-review badge, with no apply/discard controls", async () => {
    listDrafts.mockResolvedValue([sampleDraft]);
    render(<WhatsAppDraftsPanel businessId="biz-1" />);
    expect(await screen.findByText("WhatsApp updates")).toBeInTheDocument();
    expect(screen.getByText(/Suggestions only/i)).toBeInTheDocument();
    expect(screen.getAllByText(/\(suggestion\)/).length).toBeGreaterThan(0);
    expect(screen.getByText("Pending admin review")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /^apply$/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /^discard$/i })).not.toBeInTheDocument();
  });

  it("shows an Applied badge for an applied draft", async () => {
    listDrafts.mockResolvedValue([{ ...sampleDraft, status: "applied" }]);
    render(<WhatsAppDraftsPanel businessId="biz-1" />);
    expect(await screen.findByText("Applied")).toBeInTheDocument();
  });

  it("shows a Discarded badge for a discarded draft", async () => {
    listDrafts.mockResolvedValue([{ ...sampleDraft, status: "discarded" }]);
    render(<WhatsAppDraftsPanel businessId="biz-1" />);
    expect(await screen.findByText("Discarded")).toBeInTheDocument();
  });
});
