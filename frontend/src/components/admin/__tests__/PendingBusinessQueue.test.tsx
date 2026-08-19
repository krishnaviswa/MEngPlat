import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { PendingBusinessQueue } from "@/components/admin/PendingBusinessQueue";
import { businesses } from "@/lib/api";
import type { Business } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  businesses: {
    list: jest.fn(),
    approve: jest.fn(),
    suspend: jest.fn(),
    startReview: jest.fn(),
    returnToPending: jest.fn(),
  },
}));

const listMock = businesses.list as jest.Mock;
const approveMock = businesses.approve as jest.Mock;
const startReviewMock = businesses.startReview as jest.Mock;
const returnToPendingMock = businesses.returnToPending as jest.Mock;

function makeBusiness(overrides: Partial<Business> = {}): Business {
  return {
    id: "biz-1",
    name: "Biz One",
    slug: "biz-one",
    address: "1 Main St",
    city: "Metropolis",
    average_rating: 0,
    review_count: 0,
    status: "pending",
    ...overrides,
  };
}

describe("PendingBusinessQueue (S-079 admin Processing status)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC5: the queue merges both pending and processing businesses, each tagged
  // so an admin can tell the sub-state apart.
  it("loads and merges both pending and processing businesses, tagging processing rows", async () => {
    listMock.mockImplementation(({ status_filter }: { status_filter: string }) =>
      Promise.resolve(
        status_filter === "pending"
          ? [makeBusiness({ id: "b-pending", name: "Pending Biz", status: "pending" })]
          : [makeBusiness({ id: "b-processing", name: "Processing Biz", status: "processing" })],
      ),
    );

    render(<PendingBusinessQueue />);

    expect(await screen.findByText("Pending Biz")).toBeInTheDocument();
    expect(screen.getByText("Processing Biz")).toBeInTheDocument();
    expect(screen.getByText("Processing")).toBeInTheDocument();
    expect(listMock).toHaveBeenCalledWith({ status_filter: "pending" });
    expect(listMock).toHaveBeenCalledWith({ status_filter: "processing" });
  });

  // AC1: "Start review" only shows on pending rows and flips the row to processing in place.
  it("shows 'Start review' only on pending rows and moves the row to processing on click", async () => {
    listMock.mockImplementation(({ status_filter }: { status_filter: string }) =>
      Promise.resolve(status_filter === "pending" ? [makeBusiness({ id: "b-1", name: "Biz", status: "pending" })] : []),
    );
    startReviewMock.mockResolvedValue(makeBusiness({ id: "b-1", name: "Biz", status: "processing" }));

    render(<PendingBusinessQueue />);

    const startBtn = await screen.findByRole("button", { name: /start review/i });
    expect(screen.queryByRole("button", { name: /return to pending/i })).not.toBeInTheDocument();

    fireEvent.click(startBtn);

    await waitFor(() => expect(startReviewMock).toHaveBeenCalledWith("b-1"));
    expect(await screen.findByText("Processing")).toBeInTheDocument();
    expect(await screen.findByRole("button", { name: /return to pending/i })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /start review/i })).not.toBeInTheDocument();
    // Unlike approve/suspend, the row stays in the queue rather than being removed.
    expect(screen.getByText("Biz")).toBeInTheDocument();
  });

  // AC2: "Return to pending" only shows on processing rows and reverts the row in place.
  it("shows 'Return to pending' only on processing rows and reverts the row on click", async () => {
    listMock.mockImplementation(({ status_filter }: { status_filter: string }) =>
      Promise.resolve(
        status_filter === "processing" ? [makeBusiness({ id: "b-1", name: "Biz", status: "processing" })] : [],
      ),
    );
    returnToPendingMock.mockResolvedValue(makeBusiness({ id: "b-1", name: "Biz", status: "pending" }));

    render(<PendingBusinessQueue />);

    const returnBtn = await screen.findByRole("button", { name: /return to pending/i });
    fireEvent.click(returnBtn);

    await waitFor(() => expect(returnToPendingMock).toHaveBeenCalledWith("b-1"));
    expect(await screen.findByRole("button", { name: /start review/i })).toBeInTheDocument();
    expect(screen.queryByText("Processing")).not.toBeInTheDocument();
  });

  // AC3/AC8: Approve remains available (and works) on a processing row, same as pending.
  it("approves a processing business the same way as a pending one", async () => {
    listMock.mockImplementation(({ status_filter }: { status_filter: string }) =>
      Promise.resolve(
        status_filter === "processing" ? [makeBusiness({ id: "b-1", name: "Biz", status: "processing" })] : [],
      ),
    );
    approveMock.mockResolvedValue(makeBusiness({ id: "b-1", name: "Biz", status: "approved" }));

    render(<PendingBusinessQueue />);

    const approveBtn = await screen.findByRole("button", { name: /approve/i });
    fireEvent.click(approveBtn);

    await waitFor(() => expect(approveMock).toHaveBeenCalledWith("b-1"));
    // Approve/suspend remove the row from this queue entirely (existing behavior, unchanged).
    await waitFor(() => expect(screen.queryByText("Biz")).not.toBeInTheDocument());
  });

  it("shows the merged empty-state copy when both pending and processing are empty", async () => {
    listMock.mockResolvedValue([]);

    render(<PendingBusinessQueue />);

    expect(await screen.findByText("No businesses awaiting review")).toBeInTheDocument();
  });

  it("shows an inline error when start-review fails, without removing the row", async () => {
    listMock.mockImplementation(({ status_filter }: { status_filter: string }) =>
      Promise.resolve(status_filter === "pending" ? [makeBusiness({ id: "b-1", name: "Biz", status: "pending" })] : []),
    );
    startReviewMock.mockRejectedValue(new Error("Start review failed"));

    render(<PendingBusinessQueue />);

    fireEvent.click(await screen.findByRole("button", { name: /start review/i }));

    expect(await screen.findByText("Start review failed")).toBeInTheDocument();
    expect(screen.getByText("Biz")).toBeInTheDocument();
  });
});
