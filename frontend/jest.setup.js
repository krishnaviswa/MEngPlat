import "@testing-library/jest-dom";

// jsdom doesn't implement matchMedia; next-themes' ThemeProvider calls it
// (system-preference listener) whenever a test wraps a component in
// <ThemeProvider>. Without this, any such test throws
// "window.matchMedia is not a function" (S-045).
if (typeof window !== "undefined" && !window.matchMedia) {
  window.matchMedia = jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  }));
}
