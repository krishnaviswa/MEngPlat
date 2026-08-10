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
