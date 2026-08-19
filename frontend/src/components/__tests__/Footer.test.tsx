import { render, screen } from "@testing-library/react";
import { Footer } from "@/components/Footer";

describe("Footer Support column (S-087)", () => {
  it("includes a Support heading, /support link, and mailto for the published email", () => {
    render(<Footer />);

    expect(screen.getByText("Support")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /contact support/i })).toHaveAttribute("href", "/support");
    const mail = screen.getByRole("link", { name: "support@merchanthub.example" });
    expect(mail).toHaveAttribute("href", "mailto:support@merchanthub.example");
  });
});
