import { render, screen } from "@testing-library/react";
import { BusinessHours } from "@/components/BusinessHours";

describe("BusinessHours", () => {
  it("renders each day/value entry from the seeded shape", () => {
    render(<BusinessHours hours={{ "mon-fri": "7am-6pm", "sat-sun": "8am-5pm" }} />);
    expect(screen.getByText("mon-fri")).toBeInTheDocument();
    expect(screen.getByText("7am-6pm")).toBeInTheDocument();
    expect(screen.getByText("sat-sun")).toBeInTheDocument();
    expect(screen.getByText("8am-5pm")).toBeInTheDocument();
  });

  it("shows a graceful fallback when hours is null", () => {
    render(<BusinessHours hours={null} />);
    expect(screen.getByText("Hours not listed")).toBeInTheDocument();
  });

  it("shows a graceful fallback when hours is an empty object", () => {
    render(<BusinessHours hours={{}} />);
    expect(screen.getByText("Hours not listed")).toBeInTheDocument();
  });

  it("filters out null/empty-string entries but keeps usable ones", () => {
    render(<BusinessHours hours={{ mon: "9am-5pm", tue: null, wed: "" }} />);
    expect(screen.getByText("mon")).toBeInTheDocument();
    expect(screen.getByText("9am-5pm")).toBeInTheDocument();
    expect(screen.queryByText("tue")).not.toBeInTheDocument();
    expect(screen.queryByText("wed")).not.toBeInTheDocument();
  });
});
