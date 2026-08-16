# Slice: S-050 — WhatsApp link foundation (session + inbound webhook)

| Field | Value |
|-------|-------|
| **Slice ID** | S-050 |
| **Phase** | 4 Dashboards |
| **Status** | Testing |
| **Role(s)** | merchant \| admin |
| **Owner** | PM / 2026-08-16 |

---

## User story

**As a** merchant  
**I want** a dashboard link and QR that opens a WhatsApp chat to MerchantHub’s business number, bound to my listing for a short session  
**So that** I can send shop details from the app I already use, without hunting for a web form

---

## Background / context

Merchants currently have no fast channel to populate a listing (hours, description, address, photos) besides manual dashboard work. Photo upload exists (`POST /photos/upload`); there is no dedicated “edit my shop via chat” path. Most small-business owners are more comfortable sending a WhatsApp message with a few photos than filling a form.

This is the **first of three** related slices (S-050 foundation, S-051 photo ingestion, S-052 AI-extracted text drafts). Confirmed product decisions — do not re-litigate in Builder/Tester:

1. **Official Meta WhatsApp Cloud API only** (no per-message BSP markup vendors in v1).
2. **Text never goes live from the chat.** S-050 acknowledges inbound text; structured apply is S-052 (AI suggestion → merchant Apply/Discard). Photos are S-051.
3. **Session binding via a short-lived token** in the pre-filled `wa.me` message: first inbound message redeems the token and binds that WhatsApp phone to the merchant’s business for the session lifetime. Random inbound chats without a valid token must not attach to a listing.

S-050 is plumbing only: generate the link, verify Meta’s webhook, bind the session, log the inbound payload, reply with a short ack. No photo download and no AI extraction.

---

## Pre-condition (blocking, call out prominently)

**A Meta WhatsApp Cloud API app** (phone number ID, access token, webhook verify token, and signature secret as Architect specifies) **must exist before this slice can be tested end-to-end against the real API.** Until then — and permanently in local dev / CI / pytest — a `mock` WhatsApp provider stands in, mirroring `AI_PROVIDER=mock` and S-048’s mock review-source provider. Builder implements the mock first; the full flow must be buildable and testable without Meta credentials. Real-API verification is a pre-condition on e2e against WhatsApp, not a blocker on starting the slice.

---

## Acceptance criteria

1. **Given** an owning merchant (or admin) viewing an approved business on the merchant dashboard, **when** the dashboard loads, **then** a WhatsApp shop-update card is visible next to the existing review-collection QR card, showing a QR and a tappable/copyable WhatsApp deep link (not a raw API URL).
2. **Given** that card, **when** the merchant generates or refreshes the link, **then** the returned URL is a `wa.me` (or official WhatsApp click-to-chat) link to the platform business number whose pre-filled text includes a short-lived session token unique to that business — not a reusable global code shared across listings.
3. **Given** a customer, an unauthenticated caller, or a merchant who does not own the business, **when** they attempt to generate a WhatsApp link for that business, **then** the request is rejected (403/404 using the same ownership pattern as other merchant-dashboard actions).
4. **Given** Meta’s webhook verification handshake (subscribe challenge), **when** the verify token matches the configured secret, **then** the endpoint echoes the challenge and the subscription can complete; **when** the token does not match, **then** verification fails and the challenge is not echoed.
5. **Given** an inbound WhatsApp webhook POST, **when** the request is missing a signature or the signature does not verify, **then** the server returns 400 and does not process the body (same unauthenticated-but-HMAC-required pattern as the Razorpay webhook).
6. **Given** a valid signed inbound message whose text contains a still-valid unused session token, **when** the webhook is processed, **then** that sender phone is bound to the token’s business for the session lifetime, and the platform sends a short ack reply (e.g. “Got it, thanks!”) via the WhatsApp provider.
7. **Given** a valid signed inbound message with an expired, already-redeemed-invalid, or unknown token, **when** the webhook is processed, **then** no business binding is created, no listing is mutated, and the sender is not treated as that merchant (ack may explain the link expired / ask them to generate a new QR — Architect to confirm copy).
8. **Given** a bound session and a subsequent inbound **text** message from that same phone before expiry, **when** the webhook is processed, **then** the message is accepted and acknowledged, and the live public business profile is **not** changed by this slice (text apply is S-052).
9. **Given** WhatsApp provider credentials are unset (local dev / CI / pytest default `mock`), **when** link generation and inbound handling run, **then** the mock provider serves deterministic behavior (stable deep-link host/number for tests, signature verify that accepts a documented test header, ack “sent” without network) so the flow is fully testable without Meta.
10. **Given** the dashboard card, **when** the merchant uses “Print for shop”, **then** a print view similar to `CollectQrCard` is produced (QR + short instruction to scan and send shop details), pointed at the WhatsApp link rather than `/collect/{businessId}`.
11. **Given** the platform WhatsApp business number is not configured, **when** the merchant views the card, **then** they see a clear unavailable/empty state (not a broken `wa.me` with a blank number) and link generation does not pretend to succeed.

---

## UX notes

- **Screens / routes:** `/merchant/dashboard` only (`MerchantDashboard.tsx`). No new public web route. WhatsApp itself is the “form”.
- **Components to reuse:** Mirror `CollectQrCard.tsx` (`QRCodeSVG` from `qrcode.react`, “Print for shop”, card chrome, `text-muted` helper copy). New card component alongside it — do not overload the review-collection QR with a second URL.
- **Copy:** Explain in one short line that scanning opens WhatsApp to send hours, address, description, or photos; do not imply that text is published immediately (S-052 is review-before-live). No AI disclaimer on this card (this slice has no AI output).
- **Empty states / errors:** Missing platform number → AC 11. Link/API failure → readable inline error, existing collect QR unaffected. Webhook errors are not a merchant-UI concern beyond the ack in WhatsApp.
- **AI disclaimer required?** No for S-050.

---

## Out of scope

- Downloading or storing inbound photos (S-051).
- AI extraction of hours/address/description, draft rows, or Apply/Discard UI (S-052).
- Dedicated in-dashboard business hours / gallery editors (still M-55 / M-56).
- Customer-facing WhatsApp (reviews, support chatbots, broadcast campaigns).
- Third-party WhatsApp BSPs (Twilio, 360dialog, etc.) as the v1 provider — registry may allow a later adapter; none ships now.
- Two-way conversational bot flows (menus, buttons, list messages) beyond a single ack.
- Binding more than one WhatsApp phone per session, or transferring a session between businesses, in v1.

---

## Dependencies

- None blocking for Builder against the mock provider.
- **Meta WhatsApp Cloud API credentials** required before the live provider can be validated — see Pre-condition.
- S-040 (`CollectQrCard`) is the UX analog to reuse; S-048 is the integration-port analog. Neither must be reopened.
- S-051 and S-052 **must not start** until this slice is **Accepted** (they extend the inbound handler and session).

---

## Definition of done (PM)

- [ ] All 11 AC verified in test report (`docs/agents/test-reports/TR-S-050.md`), including mock-provider path
- [ ] UX matches notes — collect QR unchanged; new card is additive
- [ ] `README.md` §7 API reference updated for the merchant link action and webhook (paths as Architect specifies)
- [ ] `README.md` §6 Feature flows updated if a WhatsApp inbound flow diagram is warranted
- [ ] `README.md` §12 parity row M-79 remains accurate (web ships this slice; mobile still `unimplemented`)
- [ ] `README.md` §14 / §16 updated in the same PR (foundation shipped; photo + AI drafts still open if 051/052 not yet Accepted)
- [ ] `README.md` §15 env vars match what Architect actually wired (no fake placeholder defaults)
- [ ] No new product `.md`/`.txt` checklist outside `docs/agents/`
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

Filled as-built for the mock-first implementation ([ADR-012](../adrs/ADR-012-whatsapp-cloud-api-port.md)). Port: `app/services/whatsapp/` via `get_whatsapp_provider()`. Ingest: `whatsapp_ingest_service.py`. No Meta HTTP in routers.

### Open questions — resolved

1. **Routes:** Unauthenticated `GET|POST /api/v1/webhooks/whatsapp` (mounted in `webhooks.py`, not under `/payments`). GET is Meta’s subscribe handshake (`hub.mode`, `hub.verify_token`, `hub.challenge`). POST inbound uses header `X-Hub-Signature-256` (not Razorpay’s). Merchant action: `POST /api/v1/dashboard/merchant/{business_id}/whatsapp/link`.
2. **Session:** Token `MH-` + 8 hex (`secrets.token_hex(4).upper()`). TTL `whatsapp_session_ttl_hours` (default 24). Creating a new link **expires** other unexpired sessions for that business. Token is reusable until expiry (follow-up messages bind by `phone_e164` without repeating the token). Bound identifier is the inbound `from` string as stored (digits, not strictly validated E.164).
3. **Secrets:** HMAC uses `META_WHATSAPP_APP_SECRET` (empty default). Access token is `META_WHATSAPP_ACCESS_TOKEN` (send/download only). Verify handshake uses `META_WHATSAPP_VERIFY_TOKEN`. Mock fills verify token `mock-verify-token` and HMAC secret `mock-webhook-secret` when those settings are empty.
4. **Mock:** Number `15551234567` when `WHATSAPP_BUSINESS_NUMBER` is empty. Tests may send `X-Hub-Signature-256: sha256=mock` **or** a real HMAC of the body with `mock-webhook-secret`. `send_message` logs only. `is_available()` is always true for mock (AC11 empty state is for `meta_cloud` missing number/token).
5. **Unknown/expired token:** **Silent** — no WhatsApp reply, no bind (ADR-012). Valid bind/text ack: `Got it, thanks!`

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| POST | `/api/v1/dashboard/merchant/{business_id}/whatsapp/link` | `require_roles(MERCHANT, ADMIN)` + ownership | none | `200 WhatsAppLinkResponse` `{available, wa_url, token, expires_at, display_number}`. `403`/`404` ownership. `401` unauthenticated |
| GET | `/api/v1/webhooks/whatsapp` | none (verify token) | query `hub.mode`, `hub.verify_token`, `hub.challenge` | `200` plain-text challenge, or `403` |
| POST | `/api/v1/webhooks/whatsapp` | HMAC `X-Hub-Signature-256` | Meta JSON body | `200 WhatsAppWebhookAck` `{ok, processed}`. `400` missing/invalid sig |

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Create WhatsApp link | 403 | own business only | any business |
| Webhook GET/POST | n/a (unauthenticated; HMAC/verify token) | same | same |

### Data model impact

- [x] New table(s): `whatsapp_sessions` (`token` unique, `phone_e164` nullable until redeem, timezone `expires_at` / `redeemed_at`)

### Cache / side effects

None on link/bind. Photos (S-051) use existing storage. Apply (S-052) invalidates `search:*`.

### Frontend

- **Route:** `/merchant/dashboard` only
- **Rendering:** CSR (`WhatsAppUpdateCard`)
- **Components:** New card beside `CollectQrCard` (approved listings only). `QRCodeSVG`, Print for shop. No refresh button — each dashboard load POSTs a new link and expires prior sessions.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant Dash as WhatsAppUpdateCard
    participant API as FastAPI
    participant WA as WhatsAppProvider
    participant Meta as WhatsApp client

    Merchant->>Dash: Open approved listing
    Dash->>API: POST .../whatsapp/link
    API-->>Dash: wa.me URL + MH-XXXXXXXX
    Merchant->>Meta: Scan QR / open wa.me
    Meta->>API: POST /webhooks/whatsapp (signed)
    API->>WA: verify_signature + parse_inbound
    alt valid unused-or-unexpired token
        API->>API: bind phone_e164
        API->>WA: send_message Got it, thanks!
    else unknown or expired token
        API-->>Meta: 200 ok, processed; no bind, no ack
    end
```

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable (WhatsApp port; no AI in this slice)
- [x] ERD/API/FLOWS updates noted (`README.md` §5–§8, §7 webhooks)

### Risks / tradeoffs

- Silent unknown-token means a mistyped prefill gets no hint; merchant must reload the dashboard QR.
- Mock `sha256=mock` is a test backdoor; live `meta_cloud` never accepts it.
- S-051/S-052 share this webhook handler (photos + drafts in the same `handle_inbound`). Product originally gated 051/052 on S-050 Accepted; implementation landed together on mock.

---

## Open questions for Architect (flagged by PM)

Resolved above (routes, TTL/bind, app secret vs access token, mock HMAC, silent unknown token).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-050-whatsapp-link-foundation.md`
- Test report: `docs/agents/test-reports/TR-S-050-whatsapp-link-foundation.md`
- ADR: `docs/agents/adrs/ADR-012-whatsapp-cloud-api-port.md`
- Sibling slices: `S-051-whatsapp-photo-ingestion.md`, `S-052-whatsapp-ai-text-drafts.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-16 | PM | Created slice (Draft); technical specification left for Architect |
| 2026-08-16 | Architect | Spec filled as-built (mock-first, ADR-012); Status → Testing |
