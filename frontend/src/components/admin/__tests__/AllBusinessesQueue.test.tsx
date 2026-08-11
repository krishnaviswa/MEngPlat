import { render, screen } from "@testing-library/react";
import { AllBusinessesQueue } from "@/components/admin/AllBusinessesQueue";
import { businesses } from "@/lib/api";
import type { Business } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  businesses: { adminAll: jest.fn() },
}));

const adminAllMock = businesses.adminAll as jest.Mock;

function makeBusiness(overrides: Partial<Business> = {}): Business {
  return {
    id: "biz-1",
    name: "Biz One",
    slug: "biz-one",
    address: "1 Main St",
    city: "Metropolis",
    average_rating: 4,
    review_count: 3,
    status: "approved",
    ...overrides,
  };
}

describe("AllBusinessesQueue (S-021 AC 2 / AC 3)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC 2: lists businesses of every status, not just pending.
  it("renders businesses of every status with a status badge", async () => {
    adminAllMock.mockResolvedValue([
      makeBusiness({ id: "b-approved", name: "Approved Biz", status: "approved" }),
      makeBusiness({ id: "b-pending", name: "Pending Biz", status: "pending" }),
      makeBusiness({ id: "b-rejected", name: "Rejected Biz", status: "rejected" }),
      makeBusiness({ id: "b-suspended", name: "Suspended Biz", status: "suspended" }),
    ]);

    render(<AllBusinessesQueue />);

    expect(await screen.findByText("Approved Biz")).toBeInTheDocument();
    expect(screen.getByText("Pending Biz")).toBeInTheDocument();
    expect(screen.getByText("Rejected Biz")).toBeInTheDocument();
    expect(screen.getByText("Suspended Biz")).toBeInTheDocument();
    expect(screen.getByText("approved")).toBeInTheDocument();
    expect(screen.getByText("pending")).toBeInTheDocument();
    expect(screen.getByText("rejected")).toBeInTheDocument();
    expect(screen.getByText("suspended")).toBeInTheDocument();
  });

  // AC 3: each row is reachable without needing to know the business's slug.
  it("renders each business row as a link to its admin drill-down by id", async () => {
    adminAllMock.mockResolvedValue([makeBusiness({ id: "biz-42", name: "Drilldown Target" })]);

    render(<AllBusinessesQueue />);

    const link = await screen.findByRole("link", { name: /Drilldown Target/ });
    expect(link).toHaveAttribute("href", "/admin/businesses/biz-42");
  });

  it("shows a 'No businesses' empty state when the list is empty", async () => {
    adminAllMock.mockResolvedValue([]);

    render(<AllBusinessesQueue />);

    expect(await screen.findByText("No businesses")).toBeInTheDocument();
  });

  it("shows an inline error message when the fetch fails", async () => {
    adminAllMock.mockRejectedValue(new Error("Network down"));

    render(<AllBusinessesQueue />);

    expect(await screen.findByText("Network down")).toBeInTheDocument();
  });
});
