import { render, screen } from "@testing-library/react";
import { SOCIAL_PROOF_ENTRIES, SocialProofRail } from "@/components/home/SocialProofRail";

describe("SocialProofRail", () => {
  it("renders the small-caps label", () => {
    render(<SocialProofRail />);
    expect(screen.getByText("Businesses using MerchantHub")).toBeInTheDocument();
  });

  it("renders every SOCIAL_PROOF_ENTRIES name, not just the first", () => {
    render(<SocialProofRail />);
    expect(SOCIAL_PROOF_ENTRIES.length).toBeGreaterThan(1);
    for (const entry of SOCIAL_PROOF_ENTRIES) {
      expect(screen.getByText(entry.name)).toBeInTheDocument();
    }
  });

  it("does not display any numeric stat, count, or percentage", () => {
    const { container } = render(<SocialProofRail />);
    // Entry "initial" badges (e.g. "CK") are letters, not digits — confirm no
    // digit or "%" character appears anywhere in the rendered section text.
    const text = container.textContent ?? "";
    expect(text).not.toMatch(/\d/);
    expect(text).not.toMatch(/%/);
  });

  it("renders unconditionally (never null/empty) — component takes no props", () => {
    const { container } = render(<SocialProofRail />);
    expect(container).not.toBeEmptyDOMElement();
    expect(container.querySelector("section")).not.toBeNull();
  });

  it("does not use hardcoded light-only color literals (dark-mode-safe tokens)", () => {
    const { container } = render(<SocialProofRail />);
    const html = container.innerHTML;
    expect(html).not.toMatch(/\btext-gray-900\b/);
    expect(html).not.toMatch(/\bbg-white\b/);
  });
});
