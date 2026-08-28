import { render, screen } from "@testing-library/react";
import { Textarea } from "@/components/ui/Textarea";

describe("Textarea", () => {
  it("renders a textarea and forwards value + placeholder", () => {
    render(<Textarea value="hello" onChange={() => {}} placeholder="Your review" aria-label="Review" />);
    const el = screen.getByLabelText("Review") as HTMLTextAreaElement;
    expect(el.tagName).toBe("TEXTAREA");
    expect(el.value).toBe("hello");
    expect(screen.getByPlaceholderText("Your review")).toBe(el);
  });

  it("forwards native attributes (required, minLength, rows)", () => {
    render(<Textarea defaultValue="" required minLength={10} rows={5} aria-label="Body" />);
    const el = screen.getByLabelText("Body") as HTMLTextAreaElement;
    expect(el.required).toBe(true);
    expect(el.minLength).toBe(10);
    expect(el.rows).toBe(5);
  });

  it("carries the design-token classes so it themes correctly", () => {
    render(<Textarea aria-label="Themed" />);
    const el = screen.getByLabelText("Themed");
    expect(el).toHaveClass("border-border", "bg-surface-raised", "text-ink");
  });
});
