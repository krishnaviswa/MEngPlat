# ADR-007: Transactional email provider port (mock | Resend)

| Field | Value |
|-------|-------|
| **Status** | Proposed |
| **Date** | 2026-08-15 |
| **Slice** | S-035 |

---

## Context

MerchantHub AI has no outbound email. Password recovery, listing approval, and “new review” only exist as in-app notifications (and approval’s in-app row is currently missing from `POST /businesses/{id}/approve`). Adding a vendor SDK in routers would weld review/approve/reset to one commercial API, break local/demo without a paid key, and risk turning a failed send into a failed review or listing approve.

Password reset also needs a short-lived, single-use secret. Login lockout already uses Redis (`auth:fail:` / `auth:lock:`), but those helpers **fail open**. A reset token that fail-opens would either drop the reset silently or accept a password change with no stored challenge.

This ADR records the integration shape (a new commercial port after AI/storage) and the reset-token store.

---

## Decision

### 1. Email is a Protocol port, same shape as AI and storage

- Contract: `backend/app/services/email/base.py` — `EmailProvider` `Protocol` with a single `send(...)` (to, subject, text body, optional HTML).
- Implementations:
  - `mock.py` — **logs only** (INFO: template, to, subject, body). No vendor HTTP. No Postgres outbox table.
  - `resend.py` — Resend HTTP API adapter. `RESEND_API_KEY` stays in env; never in the repo.
- Factory: `get_email_provider()` selected by `EMAIL_PROVIDER=mock|resend` (default **`mock`**). Also `EMAIL_FROM`, and `PUBLIC_APP_URL` for reset links in copy (not a secret).
- Callers use `get_email_provider()` (or a thin `services/` helper that renders the three templates then calls `send`). Routers never import Resend.
- If `EMAIL_PROVIDER=resend` and `RESEND_API_KEY` or `EMAIL_FROM` is missing, **fail at startup** (same idea as AI/storage misconfig), not on the first review.

### 2. Why Resend (not SMTP / SES / SendGrid in v1)

Resend is a small HTTP transactional API, typed around “send this email,” with a free local-dev story of simply not using it. SMTP would mean credentials, TLS, and deliverability ops that this portfolio deploy does not have. AWS SES is another cloud account beside Railway. One adapter file is enough; a second vendor is a later `EmailProvider` implementation, not a rewrite of review/approve/reset.

### 3. Three transactional templates only

Password reset, listing approved, new review. Factual event copy. **No AI body** in v1. No marketing, digest, or subscribe UI.

### 4. Best-effort on product writes

After admin approve and after review persist (existing `Notification` path), wrap `send` in try/except, log, and **never** fail the HTTP action. Email is not a transaction participant.

### 5. Password-reset tokens in Redis, hashed, fail-closed

- Generate a high-entropy URL-safe secret; store **`sha256(token)`** in Redis (`auth:reset:{hex digest}` → user id) with TTL (1 hour). Never store the raw token.
- Prefer Redis like lockout (same process, `cache.py` / `get_redis()`), but **fail closed**: if Redis is down, `POST /auth/forgot-password` returns **503** (and reset lookup likewise). Unlike lockout, there is no safe open mode — we will not set a password without a stored challenge, and we will not claim we emailed a reset we could not record.
- Single-use: delete the key on successful `POST /auth/reset-password`.
- Public endpoints always use generic success copy for forgot (no extra account enumeration vs today’s login).

---

## Consequences

### Positive

- Local/demo and CI stay offline on `EMAIL_PROVIDER=mock` with no vendor key.
- Swapping mock → Resend is env-only; review/approve/reset flows stay vendor-agnostic.
- Review create and business approve stay reliable if the mail vendor is down.
- Reset secrets expire via Redis TTL; raw tokens never sit in Postgres.

### Negative / tradeoffs

- Forgot-password (and token lookup) **depend on Redis**. Local without Redis cannot complete reset (503), whereas login lockout still works fail-open.
- Mock has no durable outbox — Tester inspects logs, not a mailbox UI.
- Resend requires a verified sending domain in real environments; `EMAIL_FROM` must match that domain.
- Existing access JWTs are not revoked on password change (TTL ≤ 30 minutes). Out of scope for v1.
- `approve_business` does not yet write `NotificationType.APPROVAL`; S-035 must add that in-app row so email is truly “in addition to” the bell (S-015).

### Follow-ups

- README when built: §4 (why Resend), §6 reset flow, §7 auth, §9 (tokens, enumeration, Redis fail-closed), §12 parity row (web forgot/reset; mobile `unimplemented`), §14/§15 env vars. Do not add a new prose `.md`.
- Optional later: second `EmailProvider` (SES), MFA recovery-by-email, email verification (explicitly out of S-035).
- Accept this ADR when S-035 is Accepted.

---

## Alternatives considered

1. **SMTP / SES / SendGrid in v1** — more ops and secrets; rejected. Resend is one HTTP adapter; other vendors can implement the same Protocol later.
2. **JWT reset tokens (no Redis)** — works when Redis is down, but single-use/revocation still needs a store (blocklist). Conflicts with the locked fail-closed 503 on forgot.
3. **Postgres `password_reset_tokens` table** — durable, but needs a migration and expiry sweeper. Redis TTL already matches lockout’s store.
4. **Fail-open like lockout** — would either skip sending (user thinks they were emailed) or allow reset without a stored token. Rejected.
5. **Inline vendor SDK in routers** — rejected; same reason AI/storage are ports.
6. **Durable DB outbox for mock** — extra table for a Tester convenience. Locked: mock **logs only**.
