import { render, screen, waitFor } from "@testing-library/react";
import AdminWhatsAppDraftsPage from "@/app/admin/whatsapp/page";
import AdminAllReviewsPage from "@/app/admin/reviews/page";
import AdminAllBusinessesPage from "@/app/admin/businesses/page";
import { auth } from "@/lib/api";

const replaceMock = jest.fn();
const routerMock = { replace: replaceMock };

jest.mock("next/navigation", () => ({
  useRouter: () => routerMock,
}));

jest.mock("../../../lib/api", () => ({
  auth: { me: jest.fn() },
  clearTokens: jest.fn(),
}));

jest.mock("../../../components/admin/AdminWhatsAppDraftsQueue", () => ({
  AdminWhatsAppDraftsQueue: () => <div>whatsapp-queue-stub</div>,
}));
jest.mock("../../../components/admin/AllReviewsQueue", () => ({
  AllReviewsQueue: () => <div>reviews-queue-stub</div>,
}));
jest.mock("../../../components/admin/AllBusinessesQueue", () => ({
  AllBusinessesQueue: () => <div>businesses-queue-stub</div>,
}));

const meMock = auth.me as jest.Mock;

describe("Admin drill-down back links (S-086)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.setItem("access_token", "tok-1");
    meMock.mockResolvedValue({ id: "admin-1", role: "admin", full_name: "Admin" });
  });

  it("shows a back link to /admin on WhatsApp updates", async () => {
    render(<AdminWhatsAppDraftsPage />);
    const link = await screen.findByRole("link", { name: /admin panel/i });
    expect(link).toHaveAttribute("href", "/admin");
  });

  it("shows a back link to /admin on All reviews", async () => {
    render(<AdminAllReviewsPage />);
    const link = await screen.findByRole("link", { name: /admin panel/i });
    expect(link).toHaveAttribute("href", "/admin");
  });

  it("shows a back link to /admin on All businesses", async () => {
    render(<AdminAllBusinessesPage />);
    const link = await screen.findByRole("link", { name: /admin panel/i });
    expect(link).toHaveAttribute("href", "/admin");
  });

  it("denies a customer on WhatsApp updates (RequireAuth role=admin)", async () => {
    meMock.mockResolvedValue({ id: "u1", role: "customer", full_name: "Ann" });
    render(<AdminWhatsAppDraftsPage />);
    await waitFor(() => expect(replaceMock).toHaveBeenCalledWith("/"));
    expect(screen.queryByRole("link", { name: /admin panel/i })).not.toBeInTheDocument();
  });
});
