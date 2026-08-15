import { render, screen } from "@testing-library/react";
import { CollectQrCard } from "@/components/CollectQrCard";

describe("CollectQrCard (S-040)", () => {
  it("encodes the public collect URL for an approved listing", () => {
    render(<CollectQrCard businessId="biz-1" />);
    expect(screen.getByText("Review collection QR")).toBeInTheDocument();
    expect(screen.getByText(`${window.location.origin}/collect/biz-1`)).toBeInTheDocument();
    expect(screen.getByText(/no low-score intercept/i)).toBeInTheDocument();
    expect(document.querySelector("svg")).toBeTruthy();
  });
});
