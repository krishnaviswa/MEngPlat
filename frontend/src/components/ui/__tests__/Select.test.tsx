import { render, screen } from "@testing-library/react";
import { Select } from "@/components/ui/Select";

describe("Select", () => {
  it("renders options and forwards value", () => {
    render(
      <Select value="b" onChange={() => {}} aria-label="Pick">
        <option value="a">A</option>
        <option value="b">B</option>
      </Select>,
    );
    const select = screen.getByLabelText("Pick") as HTMLSelectElement;
    expect(select.value).toBe("b");
    expect(screen.getByRole("option", { name: "A" })).toBeInTheDocument();
  });
});
