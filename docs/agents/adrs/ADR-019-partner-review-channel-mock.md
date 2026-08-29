# ADR-019: Partner review channel — native reviews via a login-free token, `partners` port, mock-first

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-29 |
| **Slice** | S-123 (later partner slices consume the same port + tables) |

---

## Context

`PARTNER_REVIEW_CHANNEL_STRATEGY.md` proposes letting billing / invoicing / POS apps push
customer reviews into MerchantHub at transaction time via a free API. Before committing to
real partner integration we want to build and demo **one end-to-end mock loop** so the
team can experience the flow and decide.

Three decisions had to be pinned before any code:

1. **How partner reviews are stored** — a new `external_reviews`-style layer, or native
   `reviews`?
2. **How a customer with no MerchantHub account submits** — without weakening the organic
   login-required path.
3. **How "free" stays safe** — an unauthenticated firehose is an abuse magnet.

## Decision

### 1. Partner reviews are native `reviews` rows with a `source` marker

Not `external_reviews`. That layer (S-048) is for third-party review *content* pulled from
Google and is deliberately never blended into `Business.average_rating` / `review_count`.
A partner-sourced review is **first-party** — a real customer rating a real purchase; only
the *distribution channel* is a partner. It should count, aggregate, and moderate exactly
like a counter-QR review.

`reviews` gains `source` (`String(20)`, default `"organic"`, values `organic` | `partner`)
and `verified_purchase` (`Boolean`, default `false`). `source` is a plain string, not an
enum — same reasoning as `ExternalReview.source`: a future channel ships without a
migration.

### 2. Two-path auth — the organic path is untouched; login-free is unlocked only by a token

- **Organic** `/collect/{businessId}` → unchanged: `auth.me()`, redirect to
  `/login?next=…`, `require_roles`, `UNIQUE(author_id, business_id)`.
- **Partner** `/c/{token}` → login-free, but the capability is the **single-use,
  short-TTL token** the partner minted for one specific transaction. The end user
  controls nothing about that path — they cannot forge a token, pick a business, or
  replay one. That is the safety property, and it is why login-free is acceptable here
  and nowhere else.

The token model is copied from `WhatsAppSession` (S-050): `token`, `expires_at`,
`redeemed_at`, one business. Redeemed / expired tokens are rejected (`409` / `410`).

### 3. "Free" = zero per-call price, **not** unauthenticated

Every `POST /partner/review-requests` carries:
- `Authorization: Bearer <partner key>` — looked up by `sha256(key)` against
  `partners.api_key_hash` (raw key never stored).
- `X-MH-Signature: sha256=<hmac(raw_body, partner.hmac_secret)>` — the exact scheme
  already used for the WhatsApp (`X-Hub-Signature-256`) and Razorpay webhooks.
- `transaction_ref`, unique per partner — `UNIQUE(partner_id, partner_txn_ref)` means one
  review request per real transaction; a replay returns the existing link (idempotent).

Per-partner rate limiting and spike alarms are **noted, not built** — a real partner slice
adds them.

### 4. `PARTNERS_PROVIDER=mock` port, same shape as email / payments / sms / whatsapp

`app/services/partners/` with `base.py` (`PartnerProvider`: `verify_request_signature`,
`send_callback`), `mock.py`, and `__init__.py` (`get_partner_provider()`,
`validate_startup_config()`, `REGISTERED_PROVIDERS = ("mock",)`). Default `mock`; an
unregistered value fails at startup. The mock verifies HMAC for real; `send_callback`
logs the signed payload **and** makes a best-effort HTTP POST to the partner's URL (so
the loop closes visibly in local dev — the seeded partner points at a dev
`/partner-mock/callback-sink` that records it). A delivery failure is swallowed and never
fails the review. A dedicated `http` adapter with retry/backoff + a delivery log is still
a later slice.

### 5. Customer identity without an account — shadow users

A partner submission is authored by a pseudonymous `users` row (`role=customer`,
`auth_provider="partner"`, no email / password, `full_name="Verified customer"`). When the
partner sent a phone, the shadow user is keyed on `(business_id, sha256(secret_key +
phone))` and reused across that customer's transactions — so `UNIQUE(author_id,
business_id)` still means "one voice per customer per business" and a repeat purchaser
edits rather than double-posts. With no phone, a fresh anonymous shadow user per request.

### 6. The mock partner is server-side

The dev console at `/dev/partner-console` does **not** hold the partner secret. It calls a
dev-only `/api/v1/partner-mock/dispatch` endpoint (double-gated on `debug` **and**
`partners_provider=="mock"`) which signs as the seeded demo partner and calls the real
handler. The real `/partner/review-requests` stays HMAC-enforced and honest. The console
also surfaces the customer-facing SMS line the partner would send, the live
`pending → submitted` request list, and the signed `review.captured` callbacks received
back — so a person can watch the whole loop without reading logs.

## Consequences

### Positive
- The whole loop is clickable locally with zero vendor credentials.
- Organic review behaviour is provably unchanged (existing `test_reviews.py`).
- Native storage means partner reviews get AI themes, moderation, aggregation, and the
  merchant dashboard for free.
- Going to a real partner is: seed a `partners` row + point `PARTNERS_PROVIDER` at an
  `http` adapter. No rewrite.

### Negative / tradeoffs
- Shadow `users` rows show up in admin user search and user counts until a later slice
  filters `auth_provider="partner"`.
- `partners.hmac_secret` is stored plaintext (parity with `razorpay_webhook_secret` in
  env today); a real slice moves to hashed-at-rest / KMS.
- The mock cannot exercise real callback retry/backoff or partner-side signature quirks.
- One shared AI-analysis helper now sits between the organic router and the partner
  service — a change there hits both paths.

### Follow-ups (all gated on a written partner-pilot commitment)
- `http` callback adapter with retry/backoff + a delivery log.
- Merchant auto-provision for unknown `merchant_ref` + claim funnel.
- Partner read API + embed widget; self-serve key console; rate limiting.
- Shadow-identity → real-account merge on signup with the same phone.
- Partner data-terms / consent one-pager (README §14).

---

## Alternatives considered

1. **`external_reviews` table for partner reviews** — rejected: they would not count
   toward the rating, defeating the entire point (verified purchases should be the
   *most* trusted reviews, not invisible ones).
2. **Nullable `reviews.author_id` + partial unique index** instead of shadow users —
   rejected for this slice: `review.author` is assumed non-null across many
   queries/components; the risk/diff outweighs the benefit for a mock. Revisit if shadow
   rows become a real nuisance.
3. **Browser-side HMAC in the mock console** (secret via `NEXT_PUBLIC_`) — rejected:
   leaks a signing secret into client JS even in mock, and trains a bad pattern.
4. **Unauthenticated `POST /partner/review-requests` for the demo** — rejected: it is the
   exact abuse vector the design exists to prevent; the mock must model the real auth.
