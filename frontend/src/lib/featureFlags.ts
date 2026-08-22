/** Build-time feature flags, read from `NEXT_PUBLIC_*` env vars set on the frontend Railway service. */
export function isGamifiedReviewEnabled(): boolean {
  return process.env.NEXT_PUBLIC_GAMIFIED_REVIEW === "true";
}
