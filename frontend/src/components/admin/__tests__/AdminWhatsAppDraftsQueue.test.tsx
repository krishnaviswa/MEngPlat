import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminWhatsAppDraftsQueue } from "@/components/admin/AdminWhatsAppDraftsQueue";
import { admin } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  admin: {
    whatsappDrafts: jest.fn(),
    approveWhatsAppDraft: jest.fn(),
    rejectWhatsAppDraft: jest.fn(),
  },
}));

const listDrafts = admin.whatsappDrafts as jest.Mock;
const approveDraft = admin.approveWhatsAppDraft as jest.Mock;
const rejectDraft = admin.rejectWhatsAppDraft as jest.Mock;

const sampleDraft = {
  id: "draft-1",
  source: "whatsapp",
  business_id: "biz-1",
  business_name: "Test Cafe",
  extracted_fields: { description: "Open 9-9 near the bus stand", address: "Near the bus stand" },
  status: "pending" as const,
  degraded: false,
  created_at: "2026-08-16T00:00:00Z",
};

describe("AdminWhatsAppDraftsQueue (S-053)", () => {
  beforeEach(() => {
    listDrafts.mockReset();
    approveDraft.mockReset();
    rejectDraft.mockReset();
  });

  it("shows the empty state when there are no pending drafts", async () => {
    listDrafts.mockResolvedValue({ items: [], total: 0, page: 1, page_size: 20 });
    render(<AdminWhatsAppDraftsQueue />);
    expect(await screen.findByText("No WhatsApp suggestions waiting for review")).toBeInTheDocument();
  });

  it("lists a pending draft with business name and suggestion labeling", async () => {
    listDrafts.mockResolvedValue({ items: [sampleDraft], total: 1, page: 1, page_size: 20 });
    render(<AdminWhatsAppDraftsQueue />);
    expect(await screen.findByText("Test Cafe")).toBeInTheDocument();
    expect(screen.getAllByText(/\(suggestion\)/).length).toBeGreaterThan(0);
  });

  it("approve sends the (possibly edited) fields and removes the row", async () => {
    listDrafts.mockResolvedValue({ items: [sampleDraft], total: 1, page: 1, page_size: 20 });
    approveDraft.mockResolvedValue({ ...sampleDraft, status: "applied" });
    render(<AdminWhatsAppDraftsQueue />);
    await screen.findByText("Test Cafe");

    const descriptionInput = screen.getByDisplayValue("Open 9-9 near the bus stand");
    fireEvent.change(descriptionInput, { target: { value: "Open 8-10 near the bus stand" } });
    fireEvent.click(screen.getByRole("button", { name: /approve/i }));

    await waitFor(() =>
      expect(approveDraft).toHaveBeenCalledWith(
        "draft-1",
        expect.objectContaining({ description: "Open 8-10 near the bus stand" }),
      ),
    );
    await waitFor(() => expect(screen.queryByText("Test Cafe")).not.toBeInTheDocument());
  });

  it("reject removes the row without approving", async () => {
    listDrafts.mockResolvedValue({ items: [sampleDraft], total: 1, page: 1, page_size: 20 });
    rejectDraft.mockResolvedValue({ ...sampleDraft, status: "discarded" });
    render(<AdminWhatsAppDraftsQueue />);
    await screen.findByText("Test Cafe");

    fireEvent.click(screen.getByRole("button", { name: /reject/i }));

    await waitFor(() => expect(rejectDraft).toHaveBeenCalledWith("draft-1"));
    await waitFor(() => expect(screen.queryByText("Test Cafe")).not.toBeInTheDocument());
    expect(approveDraft).not.toHaveBeenCalled();
  });
});
