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
