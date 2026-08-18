# ADR-013: Mock Aadhaar OTP verification (no UIDAI integration)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-18 |
| **Slice** | S-070 |

---

## Context

S-043 already stores `national_id_type` (`pan` \| `aadhaar` \| `other`) and
`national_id_number` as an unverified, self-declared field on `users` — explicitly
**not** government KYC. S-070 asks for (a) structural validation of PAN/Aadhaar format
and (b) an OTP-style step for Aadhaar that *feels* like the real UIDAI Aadhaar-OTP flow
merchants may recognize, without integrating UIDAI (no license, no production data
agreement, out of scope for this product stage).

Two implementation choices needed a decision up front, because they set the pattern the
Builder must follow:

1. Where does structural validation live?
2. How is the mock OTP challenge issued/verified without inventing new OTP
   infrastructure, given `app/services/phone_otp.py` (Redis, hashed, TTL) already exists?

---

## Decision

1. **Structural validation is Pydantic-schema-level**, not a DB constraint. Add
   `field_validator`s on `UserProfileUpdate.national_id_number` (the only endpoint that
   writes this field, via `PATCH /auth/me`) that branch on the sibling
   `national_id_type`:
   - `aadhaar` → exactly 12 numeric digits (`^\d{12}$`). **No Verhoeff checksum** — this
     is a mock/demo flow (ADR context: S-070 explicitly defers real UIDAI integration),
     and Verhoeff adds real-feeling rigor to a number that was never checked against a
     government registry anyway; it would give false confidence without a corresponding
     real verification. Structural-only is the right amount of validation here.
   - `pan` → `^[A-Z]{5}[0-9]{4}[A-Z]{1}$`.
   - `other` → unchanged, free text, no new validation (S-043 behavior, AC5).
   No new DB column, no Alembic migration — this is validation logic layered on the
   existing `national_id_number` free-text column.

2. **Mock Aadhaar OTP reuses `app/services/phone_otp.py`'s primitives directly**
   (`issue_otp`, `consume_otp`, Redis-backed, 6-digit, hashed, 5-minute TTL) rather than
   a new OTP module. The Redis key is namespaced with a distinct prefix
   (`aadhaar-mock:{user_id}`) passed as the `phone` parameter — these functions only use
   that string as an opaque Redis key discriminator, so this is a safe, zero-code-change
   reuse (no edits needed to `phone_otp.py` itself). Delivery is **not** sent via
   `get_sms_provider()` to a real phone: the code is returned directly in the API
   response body (`dev_code` field) when `settings.debug` is true, exactly mirroring how
   `MockAIProvider`/mock SMS logs a code today for local development — this keeps the
   step demonstrably fake (no real SMS is ever sent for this specific mock-Aadhaar step,
   even in an environment with a real SMS provider configured for phone-login).

---

## Consequences

### Positive
- Zero new infrastructure; reuses the exact Redis/OTP pattern already proven by S-044.
- Structural-only validation keeps the "not verified KYC" framing honest — no checksum
  theatre implying more rigor than exists.
- No DB migration required for validation itself.

### Negative / tradeoffs
- Aadhaar checksum-invalid-but-structurally-valid numbers pass (acceptable — mock flow).
- Returning `dev_code` in the response body only works because this is explicitly a
  demo step; this pattern must **not** be copied for any real-verification flow later.

### Follow-ups
- If UIDAI integration is ever pursued, this validator and mock-OTP endpoint are fully
  replaced, not extended — real Aadhaar verification needs a licensed AUA/KUA
  integration, which is a separate ADR.

---

## Alternatives considered

1. Verhoeff checksum validation for Aadhaar — rejected, see Decision §1.
2. New standalone `aadhaar_otp.py` service duplicating `phone_otp.py`'s Redis logic —
   rejected, unnecessary duplication for an identical TTL/hash/consume pattern.
3. Real UIDAI Aadhaar OTP API — rejected, out of scope (no licensing), see Context.
