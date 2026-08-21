/** @type {import('next').NextConfig} */

// Origin the browser talks to directly (NEXT_PUBLIC_API_URL), so CSP connect-src/img-src
// stay scoped to it instead of falling back to a wildcard.
const apiOrigin = (() => {
  try {
    return new URL(process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000").origin;
  } catch {
    return "http://localhost:8000";
  }
})();

// 'unsafe-inline' on script/style is a pragmatic tradeoff for Next.js's own
// hydration bootstrap scripts and Tailwind's runtime style injection -- a
// nonce-based policy would remove it but needs a middleware.ts to mint and
// thread a per-request nonce, which this app doesn't have yet.
// Next.js dev mode evals webpack's source-mapped chunks, which needs
// 'unsafe-eval' -- production's build output doesn't, so keep that
// relaxation out of the policy actually served to users.
const scriptSrc = `script-src 'self' 'unsafe-inline' https://accounts.google.com${
  process.env.NODE_ENV !== "production" ? " 'unsafe-eval'" : ""
}`;

const csp = [
  "default-src 'self'",
  scriptSrc,
  "style-src 'self' 'unsafe-inline'",
  `img-src 'self' data: ${apiOrigin} https://images.unsplash.com https://picsum.photos https://*.tile.openstreetmap.org https://unpkg.com`,
  `connect-src 'self' ${apiOrigin} https://accounts.google.com https://nominatim.openstreetmap.org`,
  "frame-src https://accounts.google.com",
  "font-src 'self' data:",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join("; ");

const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: "http", hostname: "localhost", port: "8000" },
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "picsum.photos" },
    ],
  },
  async headers() {
    return [
      {
        source: "/.well-known/assetlinks.json",
        headers: [
          { key: "Content-Type", value: "application/json" },
          { key: "Cache-Control", value: "public, max-age=3600" },
        ],
      },
      {
        source: "/:path*",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(self)" },
          { key: "Content-Security-Policy", value: csp },
          { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
