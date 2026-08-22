/** @type {import('tailwindcss').Config} */
// Brand ramp mirrors the `Primitives` collection in the Figma design system
// (https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3). Keep the two in step:
// add the token in Figma first, then mirror the hex here.
module.exports = {
  darkMode: "class",
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-source-sans)", "system-ui", "sans-serif"],
        display: ["var(--font-outfit)", "var(--font-source-sans)", "system-ui", "sans-serif"],
      },
      colors: {
        brand: {
          50: "#f0f9ff",
          100: "#e0f2fe",
          200: "#bae6fd",
          300: "#7dd3fc",
          400: "#38bdf8",
          500: "#0ea5e9",
          600: "#0284c7",
          700: "#0369a1",
          800: "#075985",
          900: "#0c4a6e",
        },
        // Semantic, theme-aware tokens (S-045) — read CSS vars so one class
        // resolves correctly in both themes. Placeholder values pending a
        // human diff against the Figma Color collection (see globals.css).
        surface: "var(--mh-surface)",
        "surface-raised": "var(--mh-surface-raised)",
        ink: "var(--mh-ink)",
        muted: "var(--mh-muted)",
        border: "var(--mh-border)",
      },
      keyframes: {
        "fade-up": {
          "0%": { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "ken-burns": {
          "0%": { transform: "scale(1)" },
          "100%": { transform: "scale(1.06)" },
        },
        "reveal-in": {
          "0%": { opacity: "0", transform: "translateY(16px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        // S-119: gamified review-flow step transitions — tap-triggered, no drag/gesture library.
        "pop-in": {
          "0%": { opacity: "0", transform: "scale(0.92) translateY(8px)" },
          "100%": { opacity: "1", transform: "scale(1) translateY(0)" },
        },
        "bounce-in": {
          "0%": { opacity: "0", transform: "scale(0.7)" },
          "60%": { opacity: "1", transform: "scale(1.08)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
        "celebrate-pulse": {
          "0%": { transform: "scale(0.6)" },
          "50%": { transform: "scale(1.15)" },
          "100%": { transform: "scale(1)" },
        },
      },
      animation: {
        "fade-up": "fade-up 0.7s ease-out both",
        "ken-burns": "ken-burns 18s ease-out forwards",
        "reveal-in": "reveal-in 0.6s ease-out both",
        "pop-in": "pop-in 0.35s cubic-bezier(0.34,1.56,0.64,1) both",
        "bounce-in": "bounce-in 0.4s cubic-bezier(0.34,1.56,0.64,1) both",
        "celebrate-pulse": "celebrate-pulse 0.5s cubic-bezier(0.34,1.56,0.64,1) both",
      },
    },
  },
  plugins: [],
};
