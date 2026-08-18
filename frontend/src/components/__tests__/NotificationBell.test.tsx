import { render, screen } from "@testing-library/react";
import { NotificationBell } from "@/components/NotificationBell";
import { notifications } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  notifications: {
    list: jest.fn().mockResolvedValue([]),
    markRead: jest.fn(),
    markAllRead: jest.fn(),
  },
}));

describe("NotificationBell", () => {
  it("renders the notifications control", () => {
    render(<NotificationBell />);
    expect(screen.getByLabelText("Notifications")).toBeInTheDocument();
  });

  it("shows one row per scenario when the API returns one of each", async () => {
    const titles = [
      "Listing approved",
      "New review received",
      "WhatsApp update applied",
      "WhatsApp suggestion not applied",
      "Featured payment received",
      "Featured boost is live",
    ];
    (notifications.list as jest.Mock).mockImplementation(async (params?: { unreadOnly?: boolean }) => {
      if (params?.unreadOnly) return titles.map((title, i) => ({ id: String(i), is_read: false, title }));
      return titles.map((title, i) => ({
        id: String(i),
        type: "system",
        title,
        message: title,
        is_read: false,
        scenario: title,
        created_at: "2026-08-18T00:00:00Z",
      }));
    });
    const { getByLabelText, findAllByText } = render(<NotificationBell />);
    getByLabelText("Notifications").click();
    for (const title of titles) {
      expect(await findAllByText(title)).not.toHaveLength(0);
    }
  });
});
