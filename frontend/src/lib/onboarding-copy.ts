/** Shared copy for merchant business onboarding — kept in one place so BusinessForm's
 * ★ legend and OnboardingGuidancePanel never drift out of sync (S-072/S-074). */
export const MERCHANT_REQUIRED_FIELDS = [
  "Business name",
  "Street address",
  "City",
  "Phone",
  "Email",
  "National ID (set in your dashboard profile)",
] as const;

/** Mirrors S-043/S-070's disclaimer verbatim — never invent new wording here. */
export const NATIONAL_ID_DISCLAIMER =
  "PAN, Aadhaar, or another national ID. Stored on your account — not verified as government KYC.";
