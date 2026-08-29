# Integration rules

> Mirrors `.cursor/rules/ai-and-integrations.mdc` (Cursor `globs: backend/app/services/**/*`).
> Keep both in sync — see the parity table in the root [`CLAUDE.md`](../../../CLAUDE.md).

Volatile vendors go behind a port + factory. Routers never import SDKs.
Defaults for Compose, pytest, and staging are mock/local — see `README.md` §3 and §11.

## AI
- Implement `AIProvider` in `app/services/ai/base.py`
- Factory: `get_ai_provider()` — never call LLM APIs from routers
- Config: `AI_PROVIDER`, `AI_API_KEY`, `AI_BASE_URL`, `AI_MODEL`
- Default: `MockAIProvider` for local dev and tests

## AI copy
- Hedged language: "appears", "suggestion", "may indicate"
- Store raw response in `ai_analyses.raw_response`

## Storage
- Use `get_storage_provider()` — don't write files directly from routers
- Dev: `local`; `s3` is implemented (optional `STORAGE_S3_PUBLIC_BASE_URL` for a CDN in front of the bucket)
- `azure` is still a stub (`NotImplementedError`)

## Email
- `get_email_provider()` — `EMAIL_PROVIDER=mock|resend` (ADR-007)
- Mock logs only; never fail review/approve HTTP if send fails (best-effort)
- Password reset tokens are Redis, fail-closed

## Payments
- `get_payment_provider()` — `PAYMENTS_PROVIDER=mock|razorpay` (ADR-008)
- Three SKUs: ₹299/7d, ₹499/15d, ₹899/30d; capture then admin-approve placement; PAN never stored
- Mock + DEBUG mock-complete for Compose/pytest

## SMS
- `get_sms_provider()` — `SMS_PROVIDER=mock|msg91` (ADR-011)
- Mock logs the OTP; Msg91 for live India SMS. Phone OTP login skips TOTP (same as Google).

## Partners (review channel)
- `get_partner_provider()` — `PARTNERS_PROVIDER=mock` only for now (ADR-019, S-123)
- Mock verifies the `X-MH-Signature` HMAC **for real** (per-partner secret) and **logs**
  outbound `review.captured` callbacks instead of POSTing. An `http` adapter is a later slice.
- Partner reviews are native `reviews` rows (`source='partner'`, `verified_purchase=true`),
  never `external_reviews`. Login-free submit is unlocked only by a single-use token
  (`/api/v1/collect/{token}`); organic `/collect/{businessId}` keeps its login gate.
- `/api/v1/partner-mock/*` is double-gated on `debug` **and** `PARTNERS_PROVIDER=mock`.

## Maps
- OpenStreetMap tiles + nearby Haversine (`app/routers/maps.py` + Leaflet). Address geocoding via Nominatim was removed in S-084. Google Maps env vars are unused leftovers.
