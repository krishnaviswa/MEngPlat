import { render, screen } from "@testing-library/react";
import { ProblemSection } from "@/components/home/ProblemSection";

describe("ProblemSection", () => {
  it("renders exactly three numbered list items", () => {
    const { container } = render(<ProblemSection />);
    const items = container.querySelectorAll("ol > li");
    expect(items).toHaveLength(3);
  });

  it("renders the 01/02/03 numerals, not 1/2/3", () => {
    render(<ProblemSection />);
    expect(screen.getByText("01")).toBeInTheDocument();
    expect(screen.getByText("02")).toBeInTheDocument();
    expect(screen.getByText("03")).toBeInTheDocument();
    expect(screen.queryByText("1")).not.toBeInTheDocument();
    expect(screen.queryByText("2")).not.toBeInTheDocument();
    expect(screen.queryByText("3")).not.toBeInTheDocument();
  });

  it("renders the exact three point titles, in order", () => {
    render(<ProblemSection />);
    const headings = screen.getAllByRole("heading", { level: 3 }).map((h) => h.textContent);
    expect(headings).toEqual([
      "Your reviews are scattered",
      "You don't know what's actually working",
      "Vague reviews don't help anyone",
    ]);
  });

  it("renders unconditionally (never null/empty) — component takes no props", () => {
    const { container } = render(<ProblemSection />);
    expect(container).not.toBeEmptyDOMElement();
    expect(container.querySelector("section")).not.toBeNull();
  });

  it("does not claim live multi-platform aggregation or AI topic breakdown (honest scoping)", () => {
    const { container } = render(<ProblemSection />);
    const text = container.textContent ?? "";
    expect(text).not.toMatch(/AI/);
  });

  it("does not use hardcoded light-only color literals (dark-mode-safe tokens)", () => {
    const { container } = render(<ProblemSection />);
    const html = container.innerHTML;
    expect(html).not.toMatch(/\btext-gray-900\b/);
    expect(html).not.toMatch(/\bbg-white\b/);
  });
});
