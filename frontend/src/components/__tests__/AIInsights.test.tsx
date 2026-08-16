import { render, screen } from "@testing-library/react";
import { AIInsights } from "@/components/AIInsights";

// S-049: "Common Themes" section -- topic list rendering + suggestion/
// sentiment labeling (AC2), insufficient-data empty state (AC4), unavailable
// message (AC7), degraded prefix (AC3).
describe("AIInsights Common Themes section (S-049)", () => {
  it("renders each topic with a label, count, sentiment, and a (suggestion) label (AC1/AC2)", () => {
    render(
      <AIInsights
        insights={{
          topics: [
            { label: "Service speed", count: 12, sentiment: "positive", example_quote: "Fast service!" },
            { label: "Parking", count: 4, sentiment: "mixed", example_quote: "Parking is tight." },
          ],
        }}
      />
    );

    expect(screen.getByText("Common Themes")).toBeInTheDocument();
    expect(screen.getByText(/Service speed — 12 mentions · positive \(suggestion\)/)).toBeInTheDocument();
    expect(screen.getByText(/Parking — 4 mentions · mixed \(suggestion\)/)).toBeInTheDocument();
  });

  it("continues to show the panel's top-level disclaimer alongside topics (AC2)", () => {
    render(
      <AIInsights
        insights={{
          topics: [{ label: "Cleanliness", count: 3, sentiment: "negative", example_quote: "Tables were dirty." }],
        }}
      />
    );

    expect(
      screen.getByText("Suggestions only — not definitive judgments. Verify in person before acting.")
    ).toBeInTheDocument();
  });

  it("renders the insufficient-data empty state and no topic list (AC4)", () => {
    render(<AIInsights insights={{ topics_insufficient_data: true }} />);

    expect(screen.getByText("Common Themes")).toBeInTheDocument();
    expect(screen.getByText("Not enough reviews yet to identify common themes.")).toBeInTheDocument();
    expect(screen.queryByText(/mentions/)).not.toBeInTheDocument();
  });

  it("renders the unavailable message when topics_unavailable is true, not a crash or raw error (AC7)", () => {
    render(<AIInsights insights={{ topics_unavailable: true }} />);

    expect(screen.getByText("Common Themes")).toBeInTheDocument();
    expect(screen.getByText("Common themes are temporarily unavailable.")).toBeInTheDocument();
    expect(screen.queryByText(/mentions/)).not.toBeInTheDocument();
  });

  it("prefixes each topic with 'Mock/degraded data.' when topics_degraded is true (AC3)", () => {
    render(
      <AIInsights
        insights={{
          topics: [{ label: "Value for money", count: 5, sentiment: "mixed", example_quote: "A bit pricey." }],
          topics_degraded: true,
        }}
      />
    );

    expect(
      screen.getByText(/Mock\/degraded data\. Value for money — 5 mentions · mixed \(suggestion\)/)
    ).toBeInTheDocument();
  });

  it("does not prefix topics with the degraded label when topics_degraded is false/absent", () => {
    render(
      <AIInsights
        insights={{
          topics: [{ label: "Value for money", count: 5, sentiment: "mixed", example_quote: "A bit pricey." }],
        }}
      />
    );

    expect(screen.queryByText(/Mock\/degraded data\./)).not.toBeInTheDocument();
  });

  it("renders no Common Themes section at all when topics data hasn't loaded (no relevant fields set)", () => {
    render(<AIInsights insights={{ merchant_summary: "Business is doing fine overall." }} />);

    expect(screen.queryByText("Common Themes")).not.toBeInTheDocument();
  });
});
