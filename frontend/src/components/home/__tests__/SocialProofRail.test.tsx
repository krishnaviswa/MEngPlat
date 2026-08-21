import { render, screen } from "@testing-library/react";
import { SOCIAL_PROOF_ENTRIES, SocialProofRail } from "@/components/home/SocialProofRail";
import { businesses } from "@/lib/api";
import type { Business } from "@/lib/api";

jest.mock("../../../lib/api", () => ({
  businesses: { list: jest.fn() },
}));

const listMock = businesses.list as jest.Mock;

function seededBusiness(overrides: Partial<Business> = {}): Business {
  return {
    id: "b-1",
    name: "Copper Kettle Cafe",
    slug: "copper-kettle-cafe",
    address: "1 Main St",
    city: "Portland",
    country: "US",
    logo_url: "https://images.unsplash.com/photo-example?w=400&h=400",
    storefront_url: "https://images.unsplash.com/photo-example?w=1200&h=800",
    status: "approved",
    average_rating: 4.5,
    review_count: 10,
    categories: [],
    ...overrides,
  } as Business;
}

async function renderRail() {
  render(await SocialProofRail());
}

beforeEach(() => {
  listMock.mockReset();
});

describe("SocialProofRail", () => {
  it("renders the small-caps label", async () => {
    listMock.mockResolvedValue([seededBusiness()]);
    await renderRail();
    expect(screen.getByText("Businesses using MerchantHub")).toBeInTheDocument();
  });

  it("renders real shop photos for seeded businesses returned by the API", async () => {
    const seeded = [
      seededBusiness({ id: "b-1", name: "Copper Kettle Cafe", slug: "copper-kettle-cafe" }),
      seededBusiness({
        id: "b-2",
        name: "Verde Salon & Spa",
        slug: "verde-salon-spa",
        logo_url: "https://images.unsplash.com/photo-other?w=400&h=400",
      }),
    ];
    listMock.mockResolvedValue(seeded);
    const { container } = render(await SocialProofRail());

    expect(screen.getByText("Copper Kettle Cafe")).toBeInTheDocument();
    expect(screen.getByText("Verde Salon & Spa")).toBeInTheDocument();
    const images = container.querySelectorAll("img");
    expect(images).toHaveLength(2);
    expect(images[0].getAttribute("src")).toBe(seeded[0].storefront_url);
    expect(images[1].getAttribute("src")).toBe(seeded[1].storefront_url);
  });

  it("falls back to the initials roster when the API call fails", async () => {
    listMock.mockRejectedValue(new Error("network error"));
    const { container } = render(await SocialProofRail());

    expect(SOCIAL_PROOF_ENTRIES.length).toBeGreaterThan(1);
    for (const entry of SOCIAL_PROOF_ENTRIES) {
      expect(screen.getByText(entry.name)).toBeInTheDocument();
    }
    expect(container.querySelectorAll("img")).toHaveLength(0);
  });

  it("falls back to the initials roster when the API returns no businesses", async () => {
    listMock.mockResolvedValue([]);
    const { container } = render(await SocialProofRail());

    for (const entry of SOCIAL_PROOF_ENTRIES) {
      expect(screen.getByText(entry.name)).toBeInTheDocument();
    }
    expect(container.querySelectorAll("img")).toHaveLength(0);
  });

  it("falls back to the initials roster when the API ignores the slugs filter and returns unrelated businesses", async () => {
    // Simulates a backend that doesn't (yet) support ?slugs= and returns its whole list.
    const unrelated = Array.from({ length: 12 }, (_, i) =>
      seededBusiness({ id: `x-${i}`, name: `Random Business ${i}`, slug: `random-business-${i}` })
    );
    listMock.mockResolvedValue(unrelated);
    const { container } = render(await SocialProofRail());

    for (const entry of SOCIAL_PROOF_ENTRIES) {
      expect(screen.getByText(entry.name)).toBeInTheDocument();
    }
    expect(container.querySelectorAll("img")).toHaveLength(0);
    expect(screen.queryByText("Random Business 0")).not.toBeInTheDocument();
  });

  it("never renders more than the curated slug count, even if the API returns extras", async () => {
    const extras = Array.from({ length: 20 }, (_, i) =>
      seededBusiness({ id: `x-${i}`, name: `Extra Business ${i}`, slug: `extra-business-${i}` })
    );
    listMock.mockResolvedValue([...extras, seededBusiness()]);
    const { container } = render(await SocialProofRail());

    expect(container.querySelectorAll("img")).toHaveLength(1);
    expect(screen.getByText("Copper Kettle Cafe")).toBeInTheDocument();
  });

  it("scrolls horizontally as a single-row strip instead of wrapping", async () => {
    listMock.mockResolvedValue([seededBusiness()]);
    const { container } = render(await SocialProofRail());

    const scrollArea = container.querySelector(".overflow-x-auto");
    expect(scrollArea).not.toBeNull();
    expect(scrollArea?.querySelector(".flex-wrap")).toBeNull();
  });

  it("shows previous and next controls and does not hide the scrollbar (S-116)", async () => {
    listMock.mockResolvedValue([seededBusiness()]);
    const { container } = render(await SocialProofRail());

    expect(screen.getByRole("button", { name: "Previous shops" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Next shops" })).toBeInTheDocument();
    const scrollArea = container.querySelector(".overflow-x-auto");
    expect(scrollArea?.className).not.toMatch(/scrollbar-width:none/);
    expect(scrollArea?.className).not.toMatch(/webkit-scrollbar\]:hidden/);
  });

  it("does not display any numeric stat, count, or percentage", async () => {
    listMock.mockResolvedValue([]);
    const { container } = render(await SocialProofRail());
    const text = container.textContent ?? "";
    expect(text).not.toMatch(/\d/);
    expect(text).not.toMatch(/%/);
  });

  it("renders unconditionally (never null/empty), even on API failure", async () => {
    listMock.mockRejectedValue(new Error("network error"));
    const { container } = render(await SocialProofRail());
    expect(container).not.toBeEmptyDOMElement();
    expect(container.querySelector("section")).not.toBeNull();
  });

  it("does not use hardcoded light-only color literals (dark-mode-safe tokens)", async () => {
    listMock.mockResolvedValue([]);
    const { container } = render(await SocialProofRail());
    const html = container.innerHTML;
    expect(html).not.toMatch(/\btext-gray-900\b/);
    expect(html).not.toMatch(/\bbg-white\b/);
  });
});
