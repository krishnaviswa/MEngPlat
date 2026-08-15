import { render, screen } from "@testing-library/react";
import { Charts } from "@/components/Charts";

const sample = [
  { name: "2026-07", value: 4 },
  { name: "2026-08", value: 2 },
];

beforeAll(() => {
  (global as unknown as { ResizeObserver: unknown }).ResizeObserver = class {
    observe() {}
    unobserve() {}
    disconnect() {}
  };
});

describe("Charts variants (S-037)", () => {
  it("renders an area chart when variant is area", () => {
    const { container } = render(<Charts data={sample} variant="area" />);
    expect(container.querySelector('[data-chart-variant="area"]')).toBeTruthy();
  });

  it("renders a line chart when variant is line", () => {
    const { container } = render(<Charts data={sample} variant="line" />);
    expect(container.querySelector('[data-chart-variant="line"]')).toBeTruthy();
  });

  it("defaults to a bar chart (rating mix / sentiment)", () => {
    const { container } = render(<Charts data={sample} />);
    expect(container.querySelector('[data-chart-variant="bar"]')).toBeTruthy();
  });
});
