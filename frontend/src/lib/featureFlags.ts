/** Build-time feature flags, read from `NEXT_PUBLIC_*` env vars set on the frontend Railway service. */
export function isGamifiedReviewEnabled(): boolean {
  return process.env.NEXT_PUBLIC_GAMIFIED_REVIEW === "true";
}

/** S-123: exposes the dev-only mock billing console at `/dev/partner-console`.
 * The backend `/api/v1/partner-mock/*` endpoints are independently gated on
 * `debug` + `PARTNERS_PROVIDER=mock`; this only controls the route rendering. */
export function isPartnerMockEnabled(): boolean {
  return process.env.NEXT_PUBLIC_ENABLE_PARTNER_MOCK === "true";
}
