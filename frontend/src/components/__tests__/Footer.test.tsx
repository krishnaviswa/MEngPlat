import { render, screen } from "@testing-library/react";
import { Footer } from "@/components/Footer";

describe("Footer Support column (S-087)", () => {
  it("includes a Support heading, /support link, and mailto for the published email", () => {
    render(<Footer />);

    expect(screen.getByText("Support")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /contact support/i })).toHaveAttribute("href", "/support");
    const mail = screen.getByRole("link", { name: "support@merchanthub.example" });
    expect(mail).toHaveAttribute("href", "mailto:support@merchanthub.example");
  });
});

describe("Footer hit areas + palette (S-122)", () => {
  // AC2: every footer column link (incl. the mailto:) is a >=44px-tall tap
  // target via padding on the link box. The bottom bar has no links, so every
  // <a> in the footer is a column link.
  it("gives every column link the >=44px hit-area class", () => {
    render(<Footer />);

    const links = screen.getAllByRole("link");
    expect(links).toHaveLength(11);
    for (const link of links) {
      expect(link).toHaveClass("inline-flex");
      expect(link).toHaveClass("min-h-[44px]");
      expect(link).toHaveClass("items-center");
    }
  });

  // AC2: the mailto: link specifically also gets the hit area.
  it("gives the mailto: link the >=44px hit-area class", () => {
    render(<Footer />);
    expect(screen.getByRole("link", { name: "support@merchanthub.example" })).toHaveClass(
      "min-h-[44px]",
    );
  });

  it("uses semantic theme tokens instead of a permanently dark band", () => {
    const { container } = render(<Footer />);

    const footer = container.querySelector("footer") as HTMLElement;
    expect(footer).toHaveClass("bg-surface-raised");
    expect(footer).toHaveClass("border-border");
    expect(footer).not.toHaveClass("bg-slate-950");

    expect(screen.getByRole("link", { name: "Home" })).toHaveClass("hover:text-brand-700");
    expect(screen.getByRole("link", { name: "Home" })).toHaveClass("dark:hover:text-brand-300");

    const list = container.querySelector("ul") as HTMLElement;
    expect(list).toHaveClass("text-sm");
    expect(list).not.toHaveClass("space-y-2");
  });
});
