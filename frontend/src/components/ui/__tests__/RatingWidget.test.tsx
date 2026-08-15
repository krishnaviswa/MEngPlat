import { fireEvent, render, screen } from "@testing-library/react";
import { RatingWidget } from "@/components/ui/RatingWidget";

describe("ui/RatingWidget", () => {
  it("renders five stars", () => {
    render(<RatingWidget value={4} readonly />);
    expect(screen.getAllByRole("button")).toHaveLength(5);
  });

  it("calls onChange when interactive", () => {
    const onChange = jest.fn();
    render(<RatingWidget value={2} onChange={onChange} />);
    fireEvent.click(screen.getByLabelText("4 stars"));
    expect(onChange).toHaveBeenCalledWith(4);
  });

  it("does not call onChange when readonly", () => {
    const onChange = jest.fn();
    render(<RatingWidget value={2} onChange={onChange} readonly />);
    fireEvent.click(screen.getByLabelText("4 stars"));
    expect(onChange).not.toHaveBeenCalled();
  });
});

// S-046 AC 6 & 7: readonly half-star display for fractional averages; the
// interactive (non-readonly) picker branch is a separate code path and must
// stay whole-star only, unchanged from before this slice.
describe("ui/RatingWidget half-star display (S-046 AC 6 & 7)", () => {
  it("renders a half-star overlay on the correct star for an exact .5 value", () => {
    render(<RatingWidget value={4.5} readonly />);
    const halfStar = screen.getByLabelText("5 stars");
    expect(halfStar.querySelector('[class*="w-1/2"]')).toBeInTheDocument();
    // Stars 1-4 are full, not half.
    for (const n of [1, 2, 3, 4]) {
      expect(screen.getByLabelText(`${n} stars`).querySelector('[class*="w-1/2"]')).not.toBeInTheDocument();
    }
  });

  it("rounds a non-.5 value (4.3) to the nearest half-star (4.5) for display", () => {
    render(<RatingWidget value={4.3} readonly />);
    expect(screen.getByLabelText("5 stars").querySelector('[class*="w-1/2"]')).toBeInTheDocument();
  });

  it("renders no half-star overlay for a whole-number value", () => {
    render(<RatingWidget value={4} readonly />);
    for (const n of [1, 2, 3, 4, 5]) {
      expect(screen.getByLabelText(`${n} stars`).querySelector('[class*="w-1/2"]')).not.toBeInTheDocument();
    }
  });

  it("keeps readonly stars as disabled buttons, preserving the one-button-per-star structure", () => {
    render(<RatingWidget value={4.5} readonly />);
    const buttons = screen.getAllByRole("button");
    expect(buttons).toHaveLength(5);
    buttons.forEach((b) => expect(b).toBeDisabled());
  });

  it("the interactive picker never renders half-star overlay markup, even at a fractional value", () => {
    const onChange = jest.fn();
    render(<RatingWidget value={4} onChange={onChange} />);
    for (const n of [1, 2, 3, 4, 5]) {
      expect(screen.getByLabelText(`${n} stars`).querySelector('[class*="w-1/2"]')).not.toBeInTheDocument();
    }
  });
});
