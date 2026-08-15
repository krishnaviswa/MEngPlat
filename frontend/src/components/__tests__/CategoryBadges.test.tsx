import { render, screen } from "@testing-library/react";
import { CategoryBadges } from "@/components/CategoryBadges";

describe("CategoryBadges", () => {
  it("renders every category, not just the first", () => {
    render(
      <CategoryBadges
        categories={[
          { id: "1", name: "Café", slug: "cafe" },
          { id: "2", name: "Bakery", slug: "bakery" },
          { id: "3", name: "Vegan", slug: "vegan" },
        ]}
      />,
    );
    expect(screen.getByText("Café")).toBeInTheDocument();
    expect(screen.getByText("Bakery")).toBeInTheDocument();
    expect(screen.getByText("Vegan")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Café" })).toHaveAttribute("href", "/search?category=cafe");
    expect(screen.getByRole("link", { name: "Bakery" })).toHaveAttribute("href", "/search?category=bakery");
  });

  it("renders nothing when categories is undefined", () => {
    const { container } = render(<CategoryBadges categories={undefined} />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when categories is an empty array", () => {
    const { container } = render(<CategoryBadges categories={[]} />);
    expect(container).toBeEmptyDOMElement();
  });
});
