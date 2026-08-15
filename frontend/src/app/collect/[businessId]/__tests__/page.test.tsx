import { fireEvent, render, screen } from "@testing-library/react";
import CollectReviewPage from "@/app/collect/[businessId]/page";
import { businesses } from "@/lib/api";

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: jest.fn() }),
}));

jest.mock("../../../../lib/api", () => ({
  auth: { me: jest.fn() },
  businesses: { list: jest.fn() },
  reviews: { create: jest.fn() },
}));

function resolvedParams(value: { businessId: string }): Promise<{ businessId: string }> {
  return { status: "fulfilled", value, then() {} } as unknown as Promise<{ businessId: string }>;
}

describe("Collect review wizard", () => {
  it("does not intercept low star ratings", async () => {
    (businesses.list as jest.Mock).mockResolvedValue([
      { id: "b1", name: "Cafe", city: "Chennai", slug: "cafe", address: "1", average_rating: 4, review_count: 1 },
    ]);
    render(<CollectReviewPage params={resolvedParams({ businessId: "b1" })} />);
    expect(await screen.findByText(/Every star rating is collected the same way/i)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "1 stars" }));
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(screen.getByPlaceholderText(/at least 10 characters/i)).toBeInTheDocument();
  });
});
