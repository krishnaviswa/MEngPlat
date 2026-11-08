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

  it("renders customer notices (reply, moderation, shop edit) newest first without crashing", async () => {
    const rows = [
      { id: "1", type: "system", title: "Shop details updated", message: "Cafe A updated its details (description, phone, hours or address).",
        is_read: false, scenario: "shop_details_updated", extra_data: { business_id: "b1", changed: ["phone"] }, created_at: "2026-11-08T12:00:00Z" },
      { id: "2", type: "moderation", title: "Your review was hidden", message: "Your review of Cafe A was hidden by our moderators.",
        is_read: false, scenario: "review_moderation", extra_data: { review_id: "r1", action: "hide" }, created_at: "2026-11-08T11:00:00Z" },
      { id: "3", type: "reply", title: "Reply to your review", message: "Cafe A replied to your review.",
        is_read: true, scenario: "review_reply", extra_data: { review_id: "r1" }, created_at: "2026-11-08T10:00:00Z" },
    ];
    (notifications.list as jest.Mock).mockImplementation(async (params?: { unreadOnly?: boolean }) =>
      params?.unreadOnly ? rows.filter((r) => !r.is_read) : rows
    );
    const { getByLabelText, findAllByText, container } = render(<NotificationBell />);
    getByLabelText("Notifications").click();
    for (const row of rows) {
      expect(await findAllByText(row.title)).not.toHaveLength(0);
    }
    const order = Array.from(container.querySelectorAll("ul li button")).map((b) => b.textContent ?? "");
    expect(order.findIndex((t) => t.includes("Shop details updated"))).toBeLessThan(
      order.findIndex((t) => t.includes("Reply to your review"))
    );
  });
});
