import { fireEvent, render, screen } from "@testing-library/react";
import { StatCard } from "@/components/ui/StatCard";

describe("StatCard", () => {
  it("renders label and value", () => {
    render(<StatCard label="Total reviews" value={128} />);
    expect(screen.getByText("Total reviews")).toBeInTheDocument();
    expect(screen.getByText("128")).toBeInTheDocument();
  });

  it("renders as a link when href is set, keeping the card surface class", () => {
    render(<StatCard label="Status" value="Active" href="/businesses/x" />);
    const link = screen.getByRole("link", { name: /status/i });
    expect(link.tagName).toBe("A");
    expect(link).toHaveAttribute("href", "/businesses/x");
    expect(link).toHaveClass("rounded-xl");
  });

  it("renders as a button that fires onClick", () => {
    const onClick = jest.fn();
    render(<StatCard label="Total reviews" value={12} onClick={onClick} />);
    const btn = screen.getByRole("button", { name: /total reviews/i });
    expect(btn.tagName).toBe("BUTTON");
    fireEvent.click(btn);
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
