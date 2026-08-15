import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { ThemeProvider } from "next-themes";
import { ThemeToggle } from "@/components/ThemeToggle";

/**
 * ThemeToggle (S-045): renders a mount-guard placeholder before hydration,
 * then a labeled sun/moon button that flips `next-themes`' theme on click.
 * Requires window.matchMedia (mocked in jest.setup.js) since ThemeProvider's
 * system-preference listener calls it on mount.
 */
function renderWithTheme(defaultTheme = "light") {
  return render(
    <ThemeProvider attribute="class" defaultTheme={defaultTheme} enableSystem>
      <ThemeToggle />
    </ThemeProvider>
  );
}

describe("ThemeToggle", () => {
  it("mounts without crashing and settles on a labeled toggle button", async () => {
    renderWithTheme("light");
    // Post-mount: a labeled, clickable button is present (mount guard resolved).
    expect(await screen.findByRole("button", { name: /switch to dark mode/i })).toBeInTheDocument();
  });

  it("toggles the resolved theme on click (light -> dark)", async () => {
    renderWithTheme("light");

    const button = await screen.findByRole("button", { name: /switch to dark mode/i });
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByRole("button", { name: /switch to light mode/i })).toBeInTheDocument();
    });
    expect(document.documentElement.classList.contains("dark")).toBe(true);
    // next-themes persists the explicit choice to localStorage (default key "theme"),
    // which is what makes it survive reload/new session (AC 4).
    expect(window.localStorage.getItem("theme")).toBe("dark");
  });

  it("toggles back from dark to light", async () => {
    renderWithTheme("dark");

    const button = await screen.findByRole("button", { name: /switch to light mode/i });
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByRole("button", { name: /switch to dark mode/i })).toBeInTheDocument();
    });
  });

  it("does not crash when rendered without a ThemeProvider (context fallback)", () => {
    // next-themes' useTheme() falls back to a no-op context when there's no
    // provider; the mount-guard placeholder should still render safely.
    expect(() => render(<ThemeToggle />)).not.toThrow();
  });
});
