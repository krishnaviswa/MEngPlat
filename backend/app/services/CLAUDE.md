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
- One SKU: featured listing ₹499 / 7 days; PAN never stored
- Mock + DEBUG mock-complete for Compose/pytest

## Maps
- OpenStreetMap tiles + Nominatim (`app/routers/maps.py` + Leaflet). Google Maps env vars are unused leftovers.
