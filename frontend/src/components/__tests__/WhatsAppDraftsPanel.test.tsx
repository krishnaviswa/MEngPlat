import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { WhatsAppDraftsPanel } from "@/components/WhatsAppDraftsPanel";
import { dashboard } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  dashboard: {
    listWhatsAppDrafts: jest.fn(),
    applyWhatsAppDraft: jest.fn(),
    discardWhatsAppDraft: jest.fn(),
  },
}));

const listDrafts = dashboard.listWhatsAppDrafts as jest.Mock;
const applyDraft = dashboard.applyWhatsAppDraft as jest.Mock;
const discardDraft = dashboard.discardWhatsAppDraft as jest.Mock;

const sampleDraft = {
  id: "draft-1",
  source: "whatsapp",
  extracted_fields: { description: "Open 9-9 near the bus stand", address: "Near the bus stand" },
  status: "pending" as const,
  degraded: false,
  created_at: "2026-08-16T00:00:00Z",
};

describe("WhatsAppDraftsPanel (S-052)", () => {
  beforeEach(() => {
    listDrafts.mockReset();
    applyDraft.mockReset();
    discardDraft.mockReset();
  });

  it("renders nothing when there are no pending drafts", async () => {
    listDrafts.mockResolvedValue([]);
    const { container } = render(<WhatsAppDraftsPanel businessId="biz-1" />);
    await waitFor(() => expect(listDrafts).toHaveBeenCalled());
    expect(container.querySelector("section")).toBeNull();
  });

  it("labels extracted fields as suggestions and apply/discard", async () => {
    listDrafts.mockResolvedValue([sampleDraft]);
    applyDraft.mockResolvedValue({ ...sampleDraft, status: "applied" });
    render(<WhatsAppDraftsPanel businessId="biz-1" />);
    expect(await screen.findByText("Pending WhatsApp updates")).toBeInTheDocument();
    expect(screen.getByText(/Suggestions only/i)).toBeInTheDocument();
    expect(screen.getAllByText(/\(suggestion\)/).length).toBeGreaterThan(0);
    fireEvent.click(screen.getByRole("button", { name: /^apply$/i }));
    await waitFor(() => expect(applyDraft).toHaveBeenCalledWith("biz-1", "draft-1"));
  });

  it("discard calls the discard endpoint", async () => {
    listDrafts.mockResolvedValue([sampleDraft]);
    discardDraft.mockResolvedValue({ ...sampleDraft, status: "discarded" });
    render(<WhatsAppDraftsPanel businessId="biz-1" />);
    await screen.findByText("Pending WhatsApp updates");
    fireEvent.click(screen.getByRole("button", { name: /^discard$/i }));
    await waitFor(() => expect(discardDraft).toHaveBeenCalledWith("biz-1", "draft-1"));
  });
});
