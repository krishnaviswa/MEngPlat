import { fireEvent, render, screen } from "@testing-library/react";
import { Avatar } from "@/components/ui/Avatar";

describe("Avatar", () => {
  // S-085: renders the image when avatar_url is set, with no click/upload logic
  // of its own -- purely presentational.
  it("renders an image when avatar_url is set", () => {
    render(<Avatar user={{ full_name: "Ann Customer", avatar_url: "http://x/ann.png" }} />);

    const img = screen.getByAltText("Ann Customer");
    expect(img).toHaveAttribute("src", "http://x/ann.png");
  });

  // S-085 AC2: no avatar_url -> initials fallback (first letter of first two words).
  it("renders initials fallback when avatar_url is unset", () => {
    render(<Avatar user={{ full_name: "Ann Customer", avatar_url: null }} />);

    expect(document.querySelector("img")).not.toBeInTheDocument();
    expect(screen.getByText("AC")).toBeInTheDocument();
  });

  // S-085: a single-word name still produces a one-letter fallback rather than crashing.
  it("renders a single-letter fallback for a one-word name", () => {
    render(<Avatar user={{ full_name: "Cher", avatar_url: null }} />);

    expect(screen.getByText("C")).toBeInTheDocument();
  });

  // S-085 AC2: onError (broken/unreachable image URL) also falls back to initials,
  // not a broken-image icon or blank space.
  it("falls back to initials when the image fails to load (onError)", () => {
    render(<Avatar user={{ full_name: "Ann Customer", avatar_url: "http://x/broken.png" }} />);

    const img = screen.getByAltText("Ann Customer");
    fireEvent.error(img);

    expect(document.querySelector("img")).not.toBeInTheDocument();
    expect(screen.getByText("AC")).toBeInTheDocument();
  });
});
