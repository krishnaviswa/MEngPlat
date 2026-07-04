import { render, screen } from "@testing-library/react";
import { RatingWidget } from "@/components/RatingWidget";

describe("RatingWidget", () => {
  it("renders five stars", () => {
    render(<RatingWidget value={4} readonly />);
    expect(screen.getAllByRole("button")).toHaveLength(5);
  });
});
