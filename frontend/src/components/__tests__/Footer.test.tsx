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

  // AC2 / out-of-scope guard: palette, typography and dark styling are unchanged
  // from S-087 — spacing / hit area only.
  it("keeps the S-087 palette, typography and dark styling", () => {
    const { container } = render(<Footer />);

    const footer = container.querySelector("footer") as HTMLElement;
    expect(footer).toHaveClass("bg-slate-950");
    expect(footer).toHaveClass("border-slate-800");
    expect(footer).toHaveClass("text-slate-300");

    // hover colour on the link boxes is still the brand-300 token
    expect(screen.getByRole("link", { name: "Home" })).toHaveClass("hover:text-brand-300");

    // the 8px inter-link gap (space-y-2) and text-sm scale are retained
    const list = container.querySelector("ul") as HTMLElement;
    expect(list).toHaveClass("space-y-2");
    expect(list).toHaveClass("text-sm");
  });
});
