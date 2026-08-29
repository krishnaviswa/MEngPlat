import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import TokenCollectPage from "@/app/c/[token]/page";

jest.mock("../../../../lib/api", () => ({
  collectToken: { context: jest.fn(), submit: jest.fn() },
}));

jest.mock("../../../../components/collect/DraftEngine", () => ({ generateDraft: () => "drafted text" }));

// Real gamified sub-components render fine in jsdom; keep them to prove the wizard mounts.
import { collectToken } from "@/lib/api";

const ctxMock = collectToken.context as jest.Mock;
const submitMock = collectToken.submit as jest.Mock;

function params(token: string): Promise<{ token: string }> {
  return { status: "fulfilled", value: { token }, then() {} } as unknown as Promise<{ token: string }>;
}

const activeCtx = {
  business: { id: "b1", name: "Sri Balaji Tiffin", slug: "sri-balaji", city: "Chennai", status: "approved" as const },
  status: "pending" as const,
  expires_at: new Date(Date.now() + 86400000).toISOString(),
};

describe("Login-free token collect page (S-123)", () => {
  beforeEach(() => jest.clearAllMocks());

  it("renders the gamified wizard for a valid pending token — no login step", async () => {
    ctxMock.mockResolvedValue(activeCtx);
    render(<TokenCollectPage params={params("tok-123")} />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Sri Balaji Tiffin" })).toBeInTheDocument());
    expect(screen.getAllByText("✓ Verified purchase").length).toBeGreaterThan(0);
    // The star step of the gamified flow is showing; no "Sign in" / auth UI.
    expect(screen.queryByText(/sign in/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/log in/i)).not.toBeInTheDocument();
  });

  it("shows an expired state and never renders the wizard", async () => {
    ctxMock.mockResolvedValue({ ...activeCtx, status: "expired" });
    render(<TokenCollectPage params={params("old")} />);

    await waitFor(() => expect(screen.getByText("Review link unavailable")).toBeInTheDocument());
    expect(screen.getByText(/expired/i)).toBeInTheDocument();
  });

  it("shows an already-used state for a submitted token", async () => {
    ctxMock.mockResolvedValue({ ...activeCtx, status: "submitted" });
    render(<TokenCollectPage params={params("done")} />);

    await waitFor(() => expect(screen.getByText(/already been used/i)).toBeInTheDocument());
  });

  it("shows a not-valid state when the token 404s", async () => {
    ctxMock.mockRejectedValue(new Error("Unknown or invalid review link"));
    render(<TokenCollectPage params={params("nope")} />);

    await waitFor(() => expect(screen.getByText(/not valid/i)).toBeInTheDocument());
  });

  it("submits through the token endpoint and shows the verified-review confirmation", async () => {
    ctxMock.mockResolvedValue(activeCtx);
    submitMock.mockResolvedValue({
      review_id: "r1",
      status: "active",
      business_slug: "sri-balaji",
      verified_purchase: true,
    });
    render(<TokenCollectPage params={params("tok-123")} />);

    await waitFor(() => screen.getByRole("heading", { name: "Sri Balaji Tiffin" }));

    // stars -> chips -> text, then submit
    fireEvent.click(screen.getAllByRole("button", { name: "5 stars" }).find((b) => !b.hasAttribute("disabled"))!);
    fireEvent.click(await screen.findByRole("button", { name: /continue/i }));
    const textarea = await screen.findByPlaceholderText(/made your visit memorable/i);
    fireEvent.change(textarea, { target: { value: "Fresh food and quick service, loved it" } });
    fireEvent.click(screen.getByRole("button", { name: /submit review/i }));

    await waitFor(() => expect(submitMock).toHaveBeenCalledWith("tok-123", expect.objectContaining({ rating: 5 })));
    // CelebrationStep shows first; click through it to the confirmation card.
    fireEvent.click(await screen.findByRole("button", { name: /continue/i }));
    await waitFor(() =>
      expect(screen.getByText(/your verified review is live/i)).toBeInTheDocument(),
    );
  });
});
