import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AdminUserPanel } from "@/components/admin/AdminUserPanel";
import { admin, auth } from "@/lib/api";
import type { User } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  admin: { users: jest.fn(), suspendUser: jest.fn(), reactivateUser: jest.fn() },
  auth: { me: jest.fn() },
}));

const usersMock = admin.users as jest.Mock;
const suspendMock = admin.suspendUser as jest.Mock;
const reactivateMock = admin.reactivateUser as jest.Mock;
const meMock = auth.me as jest.Mock;

function makeUser(overrides: Partial<User> = {}): User {
  return {
    id: "u-1",
    email: "customer@example.com",
    full_name: "Cust Omer",
    role: "customer",
    is_active: true,
    ...overrides,
  };
}

describe("AdminUserPanel (S-034 AC 4 / AC 6)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "admin-self", role: "admin", full_name: "Admin" });
  });

  // AC 4: suspending a customer/merchant flips is_active to false via the Suspend button.
  it("suspends an active customer and shows Suspended", async () => {
    const customer = makeUser();
    usersMock.mockResolvedValue([customer]);
    suspendMock.mockResolvedValue({ ...customer, is_active: false });

    render(<AdminUserPanel />);

    const suspendBtn = await screen.findByRole("button", { name: /suspend/i });
    fireEvent.click(suspendBtn);

    await waitFor(() => expect(suspendMock).toHaveBeenCalledWith("u-1"));
    expect(await screen.findByText("Suspended")).toBeInTheDocument();
  });

  // AC 4: reactivating a suspended user flips is_active back to true.
  it("reactivates a suspended user and shows Active", async () => {
    const suspended = makeUser({ is_active: false });
    usersMock.mockResolvedValue([suspended]);
    reactivateMock.mockResolvedValue({ ...suspended, is_active: true });

    render(<AdminUserPanel />);

    const reactivateBtn = await screen.findByRole("button", { name: /reactivate/i });
    fireEvent.click(reactivateBtn);

    await waitFor(() => expect(reactivateMock).toHaveBeenCalledWith("u-1"));
    expect(await screen.findByText("Active")).toBeInTheDocument();
  });

  // AC 6: no suspend/reactivate control is offered for another admin row.
  it("hides the Suspend/Reactivate control for an admin row", async () => {
    const otherAdmin = makeUser({ id: "admin-2", role: "admin", full_name: "Other Admin" });
    usersMock.mockResolvedValue([otherAdmin]);

    render(<AdminUserPanel />);

    await screen.findByText("Other Admin");
    expect(screen.queryByRole("button", { name: /suspend|reactivate/i })).not.toBeInTheDocument();
  });

  // AC 6: no suspend/reactivate control is offered for the signed-in admin's own row.
  it("hides the Suspend/Reactivate control for the caller's own row", async () => {
    const self = makeUser({ id: "admin-self", role: "admin", full_name: "Me Admin" });
    usersMock.mockResolvedValue([self]);

    render(<AdminUserPanel />);

    await screen.findByText("Me Admin");
    expect(screen.queryByRole("button", { name: /suspend|reactivate/i })).not.toBeInTheDocument();
  });

  it("shows 'No users found' when the list is empty", async () => {
    usersMock.mockResolvedValue([]);

    render(<AdminUserPanel />);

    expect(await screen.findByText("No users found")).toBeInTheDocument();
  });
});

describe("AdminUserPanel search (S-080)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "admin-self", role: "admin", full_name: "Admin" });
  });

  // AC1: a search input is visible above the user list.
  it("renders a search input", async () => {
    usersMock.mockResolvedValue([makeUser()]);

    render(<AdminUserPanel />);

    expect(await screen.findByPlaceholderText("Search by name or email")).toBeInTheDocument();
  });

  // AC2/AC5: typing a term (debounced) passes it as `q` and resets to page 1.
  it("passes the search term as q and resets to page 1 after the debounce", async () => {
    usersMock.mockResolvedValue([makeUser({ full_name: "Jane Doe" })]);

    render(<AdminUserPanel />);
    await waitFor(() => expect(usersMock).toHaveBeenCalledWith({ page: 1, page_size: 20, q: undefined }));

    fireEvent.change(screen.getByPlaceholderText("Search by name or email"), { target: { value: "jane" } });

    await waitFor(
      () => expect(usersMock).toHaveBeenCalledWith({ page: 1, page_size: 20, q: "jane" }),
      { timeout: 2000 },
    );
  });

  // AC3: clearing the search box back to empty reloads the unfiltered list (q omitted).
  it("reloads the unfiltered list when the search box is cleared", async () => {
    usersMock.mockResolvedValue([makeUser()]);

    render(<AdminUserPanel />);
    await waitFor(() => expect(usersMock).toHaveBeenCalledWith({ page: 1, page_size: 20, q: undefined }));

    const input = screen.getByPlaceholderText("Search by name or email");
    fireEvent.change(input, { target: { value: "jane" } });
    await waitFor(
      () => expect(usersMock).toHaveBeenCalledWith({ page: 1, page_size: 20, q: "jane" }),
      { timeout: 2000 },
    );

    fireEvent.change(input, { target: { value: "" } });
    await waitFor(
      () => {
        const calls = usersMock.mock.calls;
        expect(calls[calls.length - 1][0]).toEqual({ page: 1, page_size: 20, q: undefined });
      },
      { timeout: 2000 },
    );
  });

  // AC4: a search with zero matches shows search-specific empty copy, distinct
  // from the "no users at all" state.
  it("shows a distinct 'no results' empty state for a search with zero matches", async () => {
    usersMock.mockResolvedValueOnce([makeUser()]).mockResolvedValueOnce([]);

    render(<AdminUserPanel />);
    await screen.findByText(makeUser().full_name);

    fireEvent.change(screen.getByPlaceholderText("Search by name or email"), { target: { value: "zzz" } });

    expect(await screen.findByText("No users match your search", {}, { timeout: 2000 })).toBeInTheDocument();
  });
});

describe("AdminUserPanel role classification badge (S-083)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    meMock.mockResolvedValue({ id: "admin-self", role: "admin", full_name: "Admin" });
  });

  // AC1/AC2: each of the three known roles renders as its own distinct badge,
  // not raw inline text.
  it("renders a distinct badge per role for customer/merchant/admin", async () => {
    usersMock.mockResolvedValue([
      makeUser({ id: "u-cust", full_name: "Cust One", role: "customer" }),
      makeUser({ id: "u-merch", full_name: "Merch One", role: "merchant" }),
      makeUser({ id: "u-admin2", full_name: "Admin Two", role: "admin" }),
    ]);

    render(<AdminUserPanel />);

    const custBadge = await screen.findByText("customer");
    const merchBadge = await screen.findByText("merchant");
    const adminBadges = await screen.findAllByText("admin");

    expect(custBadge.className).not.toBe(merchBadge.className);
    expect(merchBadge.className).not.toBe(adminBadges[0].className);
    expect(custBadge.className).not.toBe(adminBadges[0].className);
  });

  // AC3: an unmapped/future role value still renders a visible badge (raw text),
  // not a blank/broken one -- same defensive fallback as S-079's STATUS_TONE.
  it("falls back to a visible default badge for an unmapped role value", async () => {
    usersMock.mockResolvedValue([
      makeUser({ id: "u-future", full_name: "Future Role", role: "vendor" as User["role"] }),
    ]);

    render(<AdminUserPanel />);

    const badge = await screen.findByText("vendor");
    expect(badge).toBeInTheDocument();
    expect(badge.className).not.toBe("");
  });

  // AC4: both the role badge and the existing Active/Suspended badge render together.
  it("shows the role badge alongside the existing account-status badge", async () => {
    usersMock.mockResolvedValue([makeUser({ role: "merchant", is_active: true })]);

    render(<AdminUserPanel />);

    expect(await screen.findByText("merchant")).toBeInTheDocument();
    expect(screen.getByText("Active")).toBeInTheDocument();
  });

  // AC5: the caller's own (protected) admin row still shows the correct role badge.
  it("still shows the role badge on the caller's own protected admin row", async () => {
    usersMock.mockResolvedValue([makeUser({ id: "admin-self", full_name: "Me Admin", role: "admin" })]);

    render(<AdminUserPanel />);

    await screen.findByText("Me Admin");
    expect(screen.getByText("admin")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /suspend|reactivate/i })).not.toBeInTheDocument();
  });
});
