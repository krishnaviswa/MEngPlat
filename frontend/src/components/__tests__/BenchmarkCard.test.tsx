import { render, screen } from "@testing-library/react";
import { BenchmarkCard } from "@/components/BenchmarkCard";

const DISCLAIMER = "Directory medians from MerchantHub listings — not an AI judgment.";

describe("BenchmarkCard (S-038)", () => {
  it("shows directory-median disclaimer and never claims an AI verdict", () => {
    render(
      <BenchmarkCard own={4.5} categoryMedian={4.1} cityMedian={3.9} disclaimer={DISCLAIMER} />,
    );
    expect(screen.getByText(DISCLAIMER)).toBeInTheDocument();
    expect(screen.queryByText(/AI judged/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/verdict/i)).not.toBeInTheDocument();
    expect(screen.getByText("4.5")).toBeInTheDocument();
    expect(screen.getByText("4.1")).toBeInTheDocument();
    expect(screen.getByText("3.9")).toBeInTheDocument();
  });

  it("says there is not enough local data when a median is null", () => {
    render(
      <BenchmarkCard own={4.5} categoryMedian={null} cityMedian={null} disclaimer={DISCLAIMER} />,
    );
    expect(screen.getAllByText("Not enough nearby listings yet.")).toHaveLength(2);
    expect(screen.queryByText("0.0")).not.toBeInTheDocument();
  });
});
