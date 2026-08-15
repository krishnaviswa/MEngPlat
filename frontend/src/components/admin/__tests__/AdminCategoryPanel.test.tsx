import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminCategoryPanel } from "@/components/admin/AdminCategoryPanel";
import { businesses } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  businesses: { categoriesAll: jest.fn(), createCategory: jest.fn() },
}));

const categoriesAllMock = businesses.categoriesAll as jest.Mock;
const createCategoryMock = businesses.createCategory as jest.Mock;

describe("AdminCategoryPanel (S-034 AC 3)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC 3: empty category list shows the "No categories yet" empty state plus a way to add the first one.
  it("shows 'No categories yet' when the list is empty", async () => {
    categoriesAllMock.mockResolvedValue([]);

    render(<AdminCategoryPanel />);

    expect(await screen.findByText("No categories yet")).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/new category name/i)).toBeInTheDocument();
  });

  // AC 3: submitting a new category name creates it and it appears in the list.
  it("creates a category and shows it in the list", async () => {
    categoriesAllMock.mockResolvedValueOnce([]);
    createCategoryMock.mockResolvedValue({ id: "cat-1", name: "Bakery", slug: "bakery" });
    categoriesAllMock.mockResolvedValueOnce([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);
    await screen.findByText("No categories yet");

    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: "Bakery" } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));

    await waitFor(() =>
      expect(createCategoryMock).toHaveBeenCalledWith({ name: "Bakery", slug: "bakery" }),
    );
    expect(await screen.findByText("Bakery")).toBeInTheDocument();
  });

  // Backend maps duplicate name/slug to 409 -- the panel surfaces that as an inline error, not a crash.
  it("shows an inline error when create fails (e.g. duplicate name/slug 409)", async () => {
    categoriesAllMock.mockResolvedValue([]);
    createCategoryMock.mockRejectedValue(new Error("Category name or slug already exists"));

    render(<AdminCategoryPanel />);
    await screen.findByText("No categories yet");

    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: "Bakery" } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));

    expect(await screen.findByText("Category name or slug already exists")).toBeInTheDocument();
  });
});
