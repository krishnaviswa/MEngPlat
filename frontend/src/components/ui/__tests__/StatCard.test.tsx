import { render, screen } from "@testing-library/react";
import { StatCard } from "@/components/ui/StatCard";

describe("StatCard", () => {
  it("renders label and value", () => {
    render(<StatCard label="Total reviews" value={128} />);
    expect(screen.getByText("Total reviews")).toBeInTheDocument();
    expect(screen.getByText("128")).toBeInTheDocument();
  });
});
