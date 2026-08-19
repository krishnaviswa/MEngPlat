import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { ReportShopButton } from "@/components/ReportShopButton";
import { businessReports } from "@/lib/api";

const pushMock = jest.fn();

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: pushMock }),
}));

jest.mock("../../lib/api", () => ({
  businessReports: { create: jest.fn() },
}));

const createMock = businessReports.create as jest.Mock;

describe("ReportShopButton (S-089)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  it("sends the visitor to login when they submit without a token", async () => {
    render(<ReportShopButton businessId="biz-1" />);
    fireEvent.click(screen.getByRole("button", { name: /report this shop/i }));
    fireEvent.change(screen.getByPlaceholderText(/what is wrong/i), {
      target: { value: "This listing looks like a duplicate shop." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit report/i }));

    await waitFor(() => expect(pushMock).toHaveBeenCalledWith("/login"));
    expect(createMock).not.toHaveBeenCalled();
  });

  it("creates a shop report when the user is signed in", async () => {
    localStorage.setItem("access_token", "tok-1");
    createMock.mockResolvedValue({ id: "r1", status: "open" });

    render(<ReportShopButton businessId="biz-1" />);
    fireEvent.click(screen.getByRole("button", { name: /report this shop/i }));
    fireEvent.change(screen.getByPlaceholderText(/what is wrong/i), {
      target: { value: "This listing looks like a duplicate shop." },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit report/i }));

    await waitFor(() => expect(createMock).toHaveBeenCalledWith("biz-1", "This listing looks like a duplicate shop."));
    expect(await screen.findByText(/report received/i)).toBeInTheDocument();
  });
});
