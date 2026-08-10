import { render, screen } from "@testing-library/react";
import { NotificationBell } from "@/components/NotificationBell";

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
});
