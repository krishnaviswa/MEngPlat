/** @type {import('tailwindcss').Config} */
// Brand ramp mirrors the `Primitives` collection in the Figma design system
// (https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3). Keep the two in step:
// add the token in Figma first, then mirror the hex here.
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
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
      },
    },
  },
  plugins: [],
};
