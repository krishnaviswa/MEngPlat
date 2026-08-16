# ADR-012: WhatsApp Cloud API behind a mock | meta_cloud port

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-16 |
| **Slice** | S-050 (S-051, S-052 consume the same port) |

---

## Context

Merchants need a low-friction channel to send shop details and photos. Official Meta WhatsApp Cloud API is the confirmed vendor (no BSP markup). Compose, pytest, and local demo must not call Meta.

## Decision

Add `app/services/whatsapp/` with the same registry shape as `review_sources/` / `ai/`:

- `WhatsAppProvider`: `verify_webhook_challenge`, `verify_signature`, `parse_inbound`, `send_message`, `download_media`, `click_to_chat_url`, `is_available`.
- Default `WHATSAPP_PROVIDER=mock` (deterministic HMAC secret `mock-webhook-secret`, demo number `15551234567` when `WHATSAPP_BUSINESS_NUMBER` is empty).
- Live adapter `meta_cloud` when explicitly selected **and** `META_WHATSAPP_ACCESS_TOKEN` is set; otherwise the factory stays on mock.
- Webhook HMAC uses `META_WHATSAPP_APP_SECRET` (Meta signs with the app secret, not the access token). Mock uses `mock-webhook-secret` when that setting is empty.
- Session bind: short-lived `MH-XXXXXXXX` token in the `wa.me` prefill; unknown/expired tokens are **silent** (no reply) so a random chatter does not learn this number is a bot.

AI-extracted profile text is never written to `Business` until merchant Apply (S-052). Photos from a bound session use the existing storage + `Photo` path (S-051).

## Consequences

### Positive
- Tests and Compose stay vendor-free.
- Switching to live Meta is an env change, not a rewrite.

### Negative / tradeoffs
- Mock cannot exercise Meta payload quirks (status callbacks, media URL expiry).
- Silent unknown-token handling means a merchant who mistypes the token gets no WhatsApp hint; they must regenerate the dashboard QR.

### Follow-ups
- Point Meta's webhook URL at `GET|POST /api/v1/webhooks/whatsapp` when going live.

---

## Alternatives considered

1. Twilio / 360dialog BSP — rejected (per-message markup; product chose Cloud API).
2. Auto-apply AI text to the live listing — rejected (non-negotiable: suggestions only).
