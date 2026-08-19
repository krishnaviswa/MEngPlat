import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminCategoryPanel } from "@/components/admin/AdminCategoryPanel";
import { ApiError, businesses } from "@/lib/api";

jest.mock("../../../lib/api", () => {
  class ApiError extends Error {
    status: number;
    constructor(message: string, status: number) {
      super(message);
      this.name = "ApiError";
      this.status = status;
    }
  }
  return {
    ApiError,
    businesses: { categoriesAll: jest.fn(), createCategory: jest.fn() },
  };
});

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

  it("links each category chip to search filtered by slug (S-041)", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);

    const chip = await screen.findByRole("link", { name: "Bakery" });
    expect(chip).toHaveAttribute("href", "/search?category=bakery");
  });

  // S-082 AC3: a 409 duplicate-name conflict shows a specific, name-referencing message.
  it("shows a specific duplicate-name error when create fails with 409", async () => {
    categoriesAllMock.mockResolvedValue([]);
    createCategoryMock.mockRejectedValue(new ApiError("Category name or slug already exists", 409));

    render(<AdminCategoryPanel />);
    await screen.findByText("No categories yet");

    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: "Bakery" } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));

    expect(await screen.findByText('A category named "Bakery" already exists')).toBeInTheDocument();
  });
});

describe("AdminCategoryPanel search (S-081)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC1: a search input is visible above the category list.
  it("renders a search input", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);

    expect(await screen.findByPlaceholderText("Search categories")).toBeInTheDocument();
  });

  // AC2/AC6: typing a term (debounced) passes it as `q` to categoriesAll.
  it("passes the search term as q after the debounce", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);
    const input = await screen.findByPlaceholderText("Search categories");
    await waitFor(() => expect(categoriesAllMock).toHaveBeenCalledWith({ q: undefined }));

    fireEvent.change(input, { target: { value: "bak" } });

    await waitFor(() => expect(categoriesAllMock).toHaveBeenCalledWith({ q: "bak" }), { timeout: 2000 });
  });

  // AC3: clearing the box reloads the full, unfiltered list (q omitted).
  it("reloads the unfiltered list when the search box is cleared", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);
    const input = await screen.findByPlaceholderText("Search categories");
    await waitFor(() => expect(categoriesAllMock).toHaveBeenCalledWith({ q: undefined }));

    fireEvent.change(input, { target: { value: "bak" } });
    await waitFor(() => expect(categoriesAllMock).toHaveBeenCalledWith({ q: "bak" }), { timeout: 2000 });

    fireEvent.change(input, { target: { value: "" } });
    await waitFor(
      () => {
        const calls = categoriesAllMock.mock.calls;
        expect(calls[calls.length - 1][0]).toEqual({ q: undefined });
      },
      { timeout: 2000 },
    );
  });

  // AC4: a search with zero matches shows search-specific empty copy.
  it("shows a distinct 'no results' empty state for a search with zero matches", async () => {
    categoriesAllMock.mockResolvedValueOnce([{ id: "cat-1", name: "Bakery", slug: "bakery" }]).mockResolvedValueOnce([]);

    render(<AdminCategoryPanel />);
    await screen.findByText("Bakery");

    fireEvent.change(screen.getByPlaceholderText("Search categories"), { target: { value: "zzz" } });

    expect(await screen.findByText("No categories match your search", {}, { timeout: 2000 })).toBeInTheDocument();
  });

  // AC5: filtered chips still link to /search?category={slug} unchanged.
  it("keeps chip links unchanged while a filter is active", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);

    render(<AdminCategoryPanel />);
    fireEvent.change(await screen.findByPlaceholderText("Search categories"), { target: { value: "bak" } });

    const chip = await screen.findByRole("link", { name: "Bakery" });
    expect(chip).toHaveAttribute("href", "/search?category=bakery");
  });

  // AC7: adding a category while a filter is active still works normally.
  it("still creates a category successfully while a search filter is active", async () => {
    categoriesAllMock.mockResolvedValue([{ id: "cat-1", name: "Bakery", slug: "bakery" }]);
    createCategoryMock.mockResolvedValue({ id: "cat-2", name: "Cafe", slug: "cafe" });

    render(<AdminCategoryPanel />);
    fireEvent.change(await screen.findByPlaceholderText("Search categories"), { target: { value: "bak" } });
    await waitFor(() => expect(categoriesAllMock).toHaveBeenCalledWith({ q: "bak" }), { timeout: 2000 });

    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: "Cafe" } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));

    await waitFor(() => expect(createCategoryMock).toHaveBeenCalledWith({ name: "Cafe", slug: "cafe" }));
  });
});

describe("AdminCategoryPanel distinct 'Add category' error states (S-082)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    categoriesAllMock.mockResolvedValue([]);
  });

  async function submit(name = "Bakery") {
    await screen.findByText("No categories yet");
    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: name } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));
  }

  // AC4: 401/403 shows a distinct auth-failure message.
  it("shows a session/permission message for a 401", async () => {
    createCategoryMock.mockRejectedValue(new ApiError("Not authenticated", 401));

    render(<AdminCategoryPanel />);
    await submit();

    expect(
      await screen.findByText("Your session has expired or you don't have permission. Sign in again as an admin."),
    ).toBeInTheDocument();
  });

  it("shows the same session/permission message for a 403", async () => {
    createCategoryMock.mockRejectedValue(new ApiError("Forbidden", 403));

    render(<AdminCategoryPanel />);
    await submit();

    expect(
      await screen.findByText("Your session has expired or you don't have permission. Sign in again as an admin."),
    ).toBeInTheDocument();
  });

  // AC5: a 5xx server error shows a distinct "our end" message.
  it("shows a server-error message for a 500", async () => {
    createCategoryMock.mockRejectedValue(new ApiError("Internal Server Error", 500));

    render(<AdminCategoryPanel />);
    await submit();

    expect(await screen.findByText("Something went wrong on our end. Please try again.")).toBeInTheDocument();
  });

  // AC5: a true network failure (fetch itself rejects, no Response/status) shows a
  // distinct "check your connection" message -- not the 5xx copy.
  it("shows a network-problem message when the request never reaches the server", async () => {
    createCategoryMock.mockRejectedValue(new TypeError("Failed to fetch"));

    render(<AdminCategoryPanel />);
    await submit();

    expect(
      await screen.findByText("Network problem — check your connection and try again."),
    ).toBeInTheDocument();
  });

  // AC6: a stale error clears on a fresh, successful resubmit.
  it("clears a previous error on a successful resubmit", async () => {
    createCategoryMock.mockRejectedValueOnce(new ApiError("Category name or slug already exists", 409));
    createCategoryMock.mockResolvedValueOnce({ id: "cat-1", name: "Cafe", slug: "cafe" });

    render(<AdminCategoryPanel />);
    await submit("Bakery");
    expect(await screen.findByText('A category named "Bakery" already exists')).toBeInTheDocument();

    fireEvent.change(screen.getByPlaceholderText(/new category name/i), { target: { value: "Cafe" } });
    fireEvent.click(screen.getByRole("button", { name: /add category/i }));

    await waitFor(() =>
      expect(screen.queryByText('A category named "Bakery" already exists')).not.toBeInTheDocument(),
    );
  });
});
