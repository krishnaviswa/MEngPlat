# Slice: S-035 — Transactional email

| Field | Value |
|-------|-------|
| **Slice ID** | S-035 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** customer or merchant
**I want** the platform to email me when I request a password reset, when my listing is approved, and when a new review is posted on my business
**So that** I can recover access and hear about those events even when I am not signed in to the app

**Why this slice:** There is no outbound email today. In-app notifications already cover some of the same events (S-015 / S-008). This is the first commercial integration after analytics: a small, transactional set of messages — not a marketing channel.

---

## Acceptance criteria

1. **Given** the platform is configured with no vendor send key (local/demo default), **when** any of the three v1 emails would be sent, **then** send goes through the same kind of provider/port already used for AI and storage (swap mock vs real without rewriting review/approve/reset flows), the mock records the message only (logs and/or an outbox Tester can inspect), and **no** vendor network call is required. **Given** a send fails (mock error or vendor error), **when** a customer submits a review or an admin approves a listing, **then** that core action still succeeds (review created / listing approved, existing in-app notification still created) — email is best-effort, never a blocker.
2. **Given** an existing account (any role that can sign in with email/password), **when** I request a password-reset email for that account’s address, **then** a password-reset message is queued/sent for that address. **Given** an address that is not registered (or I am not told whether it is), **when** I submit the same request, **then** the on-screen copy and HTTP outcome do **not** confirm whether that email exists — no extra account enumeration compared with today’s login (generic “if an account exists…” / same success path for known and unknown).
3. **Given** I am a merchant with a pending listing, **when** an admin approves that listing, **then** I receive a “listing approved” email **in addition to** the existing in-app approval notification (S-015). The email is event copy only (business name / that the listing is now live), not a marketing blast.
4. **Given** I am a merchant with an approved business, **when** a customer submits a review on that business, **then** I receive a “you have a new review” email **in addition to** the existing in-app review notification. The email does not replace the in-app bell.
5. **Given** any send in this slice, **when** Tester inspects templates and triggers, **then** every template is **transactional only** (password reset, listing approved, new review). There is no newsletter, promo, or campaign template and no UI to subscribe/unsubscribe from marketing.
6. **Given** local/demo with the mock provider, **when** I use the product without a vendor key and without internet to a mail vendor, **then** password reset, listing approval, and review submit still work end-to-end, and the three emails appear in logs/outbox so a developer or Tester can confirm they would have been sent.
7. **Given** v1 email bodies, **when** they are rendered, **then** they contain **no AI-generated body** (no sentiment, no suggested reply, no insights pasted into the mail). Copy is factual event text only. **If** a later change puts AI-derived text in an email, that text must be labeled as a **suggestion**, never a definitive judgment — v1 should not need that disclaimer because it should not include AI content.

---

## UX notes

- **Screens / routes:** No new marketing or “email settings” page. No new merchant dashboard screen — merchants keep using `/merchant/dashboard` and the existing notification bell. Password reset may add a **Forgot password** control on `/login` (`LoginForm` today has email/password + Google only; there is no reset entry). If a complete-reset screen is required so the email is usable, it should be a small, beginner-friendly form (new password + confirm), not a campaign landing page.
- **Components to reuse:** Existing `LoginForm` / login page patterns (`Button`, form layout, error text). Do not invent a notifications-preferences screen. Do not add tiles or inbox UI for email.
- **Empty states / errors:** Forgot-password request always shows a **generic** confirmation (same for known and unknown addresses). Send failures are invisible to the customer/merchant on review submit and listing approve (those flows already have their own success/error UX). Demo/mock: developers see mail in logs/outbox, not a user-facing mailbox product.
- **AI disclaimer required?** No for v1 — bodies are event copy, not AI output. AC 7 forbids AI body in v1; if that ever changes, suggestion language is mandatory.

---

## Out of scope

- Marketing campaigns, newsletters, drip sequences, or a subscribe/unsubscribe marketing UI.
- Digest emails (daily/weekly roundups).
- A Resend (or other vendor) dashboard UI inside MerchantHub.
- Payments / PCI (tracked separately as **S-036**).
- Push / FCM / APNs (mobile push remains `future` in the §12 tracker; in-app notifications stay as they are).
- Changing which in-app notification types exist, or replacing the bell.
- Email change / verification of a new address (profile email stays read-only per S-016).
- Admin-as-primary recipient for these three events (admin may still request password reset as an existing account per AC 2).

---

## Dependencies

- **Commercial-plan order:** after **S-033** / **S-034** (analytics-related commercial work). That is sequencing for the backlog, **not** a hard code dependency — this slice can be specified and built without those slices being Accepted.
- S-001 Auth (login, existing accounts) — already shipped.
- S-002 Business CRUD + admin approval — already shipped (approval is the trigger for AC 3).
- S-003 Reviews — already shipped (submit is the trigger for AC 4).
- S-008 / S-015 In-app notifications — already shipped; this slice **adds** email beside them, it does not replace them.

---

## Definition of done (PM)

- [x] All AC verified in test report
- [x] UX matches notes above (no marketing page; optional forgot-password on `/login`; no new merchant dashboard screen)
- [x] Documented in `README.md` §6 Feature flows (reset + the two merchant emails), §7 API reference if new/changed auth or send surfaces, §8 Frontend guide if `/login` grows a reset entry, §9 Security if reset tokens/enumeration behavior is documented, §12 Web ↔ mobile feature parity tracker (forgot-password / transactional mail on web → mobile row, usually `unimplemented` until a later mobile slice), §14 / §15 if the “no outbound email” gap and env/provider are listed
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

### API contract

Style matches `README.md` §7 Authentication — `/auth`. **Do not add extra mail endpoints** (no send-test, no list-outbox, no merchant email settings). Review create and business approve keep their existing paths; email is a side effect.

| Method | Path | Auth | Request | Response | Errors |
|--------|------|------|---------|----------|--------|
| POST | `/api/v1/auth/forgot-password` | Public | `{ "email": string }` (`EmailStr`) | **Always 200** `{ "message": "<generic if-account-exists copy>" }` for any well-formed address (registered, unknown, Google-only, inactive). Same body either way. | **422** invalid email shape. **429** rate limit (`slowapi` **5/minute per IP**, same family as register). **503** Redis unreachable (cannot store hashed token — fail-closed). **Never 404** for unknown email. |
| POST | `/api/v1/auth/reset-password` | Public | `{ "token": string, "new_password": string }` — `new_password` **same policy as register**: min 12, at least one letter and one digit (`UserRegister` validator reused, not a weaker rule) | **200** `{ "message": "Password updated. Sign in with your new password." }` — **no session tokens** (next login still TOTP per ADR-001) | **422** password policy. **400** generic invalid/expired/used token (do not distinguish). **429** 5/minute per IP. **503** Redis down (cannot look up token). |
| POST | `/api/v1/reviews` | Bearer customer (existing) | Unchanged | Unchanged review payload | Unchanged. Send failure **must not** become 5xx. |
| POST | `/api/v1/businesses/{business_id}/approve` | Bearer admin (existing) | Unchanged | Unchanged `BusinessResponse` | Unchanged. Send failure **must not** become 5xx. |

Forgot success copy (illustrative; keep one string for known and unknown): *If an account exists for that email, we sent password-reset instructions.*

Reset email link: `{PUBLIC_APP_URL}/reset-password?token={raw_token}` (raw token only in the message, never logged in full).

When built, update `README.md` §7 `/auth` table + example payloads; do not invent a `/email` router.

### RBAC matrix

| Action | customer | merchant | admin | unauthenticated |
|--------|----------|----------|-------|-----------------|
| POST `/auth/forgot-password` | yes (public; any role with a password account may receive mail) | yes | yes (AC 2) | yes |
| POST `/auth/reset-password` | yes (public; token proves possession) | yes | yes | yes |
| Receive **password-reset** email | only if a **password** account exists for that address (`hashed_password` set). Google-only (`hashed_password is None`): **no send**, still 200 generic | same | same | n/a |
| Receive **listing approved** email | no | yes — owner of the approved business (`Merchant.user_id` → `User.email`) | no (admin is actor, not recipient) | no |
| Receive **new review** email | no (reviewer is not mailed) | yes — owner of the reviewed business | no | no |
| Merchant email-settings page | — | **no** (out of scope) | — | — |

Do **not** extra-enumerate: no “email not found”, no different status/timing API for unknown vs known, no register/welcome/verify mail, no mail on review **edit**, reply, reject, or suspend.

### Data model impact

- [x] None (Postgres)  [ ] Extend existing  [ ] New table(s)

**Details:**

- No new tables, enums, or Alembic revision for mail.
- Reset state lives in **Redis**, not Postgres: key `auth:reset:{sha256(utf-8 token).hexdigest()}` → `user_id` (UUID string), TTL **3600s**, single-use (DELETE on successful reset). Hash with SHA-256 (token is high-entropy; do not bcrypt).
- **In-app gap to close in this slice (not a new product):** `NotificationType.APPROVAL` exists but `approve_business` does not insert a `Notification` today. After setting `Business.status = APPROVED`, persist `Notification` (`type=APPROVAL`, merchant’s `user_id`, title/message with **business name**, listing now live) **then** best-effort email. Review path already inserts `NotificationType.REVIEW` in `reviews.py` — hook email **after that persist**, same request (or `BackgroundTasks` with internal try/except).
- ERD (`README.md` §5): **no change**. Redis key is documented in §9 when built, not as a table.

### Email port (mirror AI / storage)

| Piece | Path / name |
|-------|-------------|
| Protocol | `backend/app/services/email/base.py` — `EmailProvider` |
| Mock | `backend/app/services/email/mock.py` — **logs only** (INFO: template id, to, subject, text). No network, no DB outbox. |
| Resend | `backend/app/services/email/resend.py` — HTTP adapter (reuse **httpx** like AI; do not call Resend from routers) |
| Factory | `get_email_provider()` in `backend/app/services/email/__init__.py` |

Settings (`config.py` + `.env.example` placeholders only — **no secrets in git**):

| Env | Default | Notes |
|-----|---------|--------|
| `EMAIL_PROVIDER` | `mock` | `mock` \| `resend` |
| `RESEND_API_KEY` | empty | Required at **startup** if provider is `resend` |
| `EMAIL_FROM` | empty | Required at startup if `resend` (verified domain in real env) |
| `PUBLIC_APP_URL` | `http://localhost:3000` | Origin for reset links; not a secret |

Templates (v1 only — event copy, **no AI** text, no sentiment/suggested reply):

1. `password_reset` — link + short expiry note.
2. `listing_approved` — business name; listing is live.
3. `new_review` — business name; a new review was posted (stars optional as factual; **no** AI summary).

Thin `services/` helper (not routers): `try_send_*` catches **all** send exceptions, logs, returns. Review create and business approve **must** call that helper (or equivalent) so a throw cannot roll back the unit of work.

### Cache / side effects

- **Search cache:** unchanged. Approve already `cache_delete_pattern("search:*")`; reviews already do. Email does not touch `search:*`.
- **Redis lockout** (`auth:fail:` / `auth:lock:`) stays **fail-open**. **Reset keys are fail-closed** (see ADR-007): forgot/reset return 503 if Redis errors. Do not reuse `cache_set`/`cache_get` (those swallow errors).
- **Best-effort send:** never fail review create or business approve if `send` throws — catch and log.
- Forgot: if the user qualifies, write Redis **then** try send; if send fails, still **200 generic** (same as unknown email). If Redis fails **before** write → **503** (does not reveal whether the email exists).
- Password update: `hashed_password = get_password_hash(new_password)` only. Do not disable TOTP. Do not issue JWTs. Google-only accounts are not converted via this flow (no token was stored).
- Rate-limit forgot/reset like other public auth POSTs.

### Frontend

- **Route:** `/login` — “Forgot password?” control on `LoginForm` (credentials step only; not enroll/verify). `/forgot-password` — email field + generic confirmation. `/reset-password` — `token` query + new password + confirm (beginner-friendly). **No** merchant email settings page.
- **Rendering:** CSR (`"use client"`), same as `/login`.
- **Components:** Reuse `Button`, form layout, error text from `LoginForm`. Extend `frontend/src/lib/api.ts` `auth` with `forgotPassword` / `resetPassword`. Do not add notification-preference or mailbox UI.
- **§12 when built:** new web capability → tracker row (forgot/reset + transactional mail), mobile usually `unimplemented` until a later slice.

### Flow

```mermaid
sequenceDiagram
    participant User
    participant Web as Frontend
    participant API
    participant Redis
    participant Mail as EmailProvider
    participant DB

    Note over User,Mail: Password reset
    User->>Web: Forgot password (email)
    Web->>API: POST /api/v1/auth/forgot-password
    alt Redis down
        API-->>Web: 503
    else Redis up
        API->>DB: Lookup user by email (password account?)
        opt Qualifying account
            API->>Redis: SET auth:reset:{sha256(token)} user_id EX 3600
            API->>Mail: send password_reset (try/except; log on fail)
        end
        API-->>Web: 200 generic (always)
    end
    User->>Web: /reset-password?token=
    Web->>API: POST /api/v1/auth/reset-password
    API->>Redis: GET hashed token
    alt Missing/expired/used or Redis down
        API-->>Web: 400 or 503
    else Valid + policy OK
        API->>DB: Update hashed_password
        API->>Redis: DEL key
        API-->>Web: 200 (no tokens)
    end

    Note over User,Mail: Listing approved (existing approve + in-app)
    User->>API: POST /businesses/{id}/approve (admin)
    API->>DB: status=approved + AuditLog + Notification APPROVAL
    API->>Mail: try listing_approved (never fail approve)
    API-->>User: BusinessResponse

    Note over User,Mail: New review (existing notification path)
    User->>API: POST /reviews
    API->>DB: Review + AI + Notification REVIEW
    API->>Mail: try new_review (never fail create)
    API-->>User: ReviewResponse
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 API reference style
- [x] RBAC matrix for all roles
- [x] Data model impact documented; ERD update noted if needed (none)
- [x] Cache invalidation considered (search unchanged; Redis reset keys fail-closed)
- [x] AI/storage/maps use existing abstraction layers (email **mirrors** AI/storage port; no AI in mail bodies)
- [x] No secrets in design (`RESEND_API_KEY` env only)
- [x] ERD/API/FLOWS updates noted for Builder (`README.md` §4 Resend, §6 reset, §7 auth, §8 routes, §9, §12, §14/§15)

### Risks / tradeoffs

- **Redis required for reset** — stricter than lockout fail-open; local without Redis cannot finish forgot (503). Document in §9.
- **Mock = logs only** — Tester greps logs; no mailbox product.
- **Approve notification gap** — must insert `APPROVAL` notification in this slice so AC 3 is true.
- **Timing side channel** — unknown vs known may differ in DB/Redis/send work; v1 accepts that (no dummy send); HTTP outcome stays identical.
- **Sessions after reset** — outstanding access tokens remain valid until expiry; v1 does not global-revoke.
- **Resend domain verification** — production `EMAIL_FROM` must be allowed by Resend; misconfig fails startup when `EMAIL_PROVIDER=resend`.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-035-*.md`
- Test report: `docs/agents/test-reports/TR-S-035-*.md`
- ADR: [`docs/agents/adrs/ADR-007-transactional-email-port.md`](../adrs/ADR-007-transactional-email-port.md)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM | Created slice. First outbound-email commercial integration after analytics: password reset, listing approved, new review for merchant. Email behind a provider port (mock when no vendor key); best-effort so review/approve never fail on send. No extra email enumeration vs current login. Transactional templates only; v1 bodies are event copy with no AI. Local/demo works offline via logs/outbox. No marketing page, no new merchant dashboard; forgot-password on `/login` if missing. Out of scope: campaigns, digests, vendor dashboard UI, S-036 payments, FCM. Soft backlog order after S-033/S-034, not a hard code dependency. Status: **Draft**. Handoff: Architect fills Technical specification, then Status → Specified. |
| 2026-08-15 | Architect | Technical specification: email Protocol port (`base` / `mock` logs-only / `resend` + `get_email_provider()`), best-effort hooks after approve and review persist, public forgot/reset auth APIs (generic 200; Redis hashed tokens fail-closed 503), no extra mail types, `/login` + `/forgot-password` + `/reset-password` CSR, no merchant email settings. ADR-007 Proposed. Status: **Specified**. Handoff: Builder. |
| 2026-08-15 | Builder | Implemented per spec: `backend/app/services/email/{base,mock,resend,templates,__init__}.py` (Protocol port, `get_email_provider()`, `validate_startup_config()` wired into `main.py` lifespan, `try_send_password_reset`/`try_send_listing_approved`/`try_send_new_review` catch-all-and-log helpers); `backend/app/services/password_reset.py` (SHA-256-hashed single-use Redis tokens, 1h TTL, fail-closed — raises instead of swallowing, unlike `cache.py`). `POST /auth/forgot-password` pings Redis *before* the account lookup so the 503 path doesn't itself distinguish known vs unknown addresses, then always returns the generic message; `POST /auth/reset-password` returns generic 400 for missing/expired/used tokens, updates `hashed_password` only (no tokens issued, TOTP untouched). `approve_business` now inserts the missing `NotificationType.APPROVAL` row (closing the ADR-007-flagged gap) then best-effort emails the merchant; `create_review` best-effort emails the business owner after the existing `NotificationType.REVIEW` insert. New settings `EMAIL_PROVIDER`/`RESEND_API_KEY`/`EMAIL_FROM`/`PUBLIC_APP_URL` in `config.py` + `.env.example` + `docker-compose.yml`. Frontend: `auth.forgotPassword`/`auth.resetPassword` in `api.ts`; new `ForgotPasswordForm`/`ResetPasswordForm` components + `/forgot-password`/`/reset-password` pages (CSR, mirror `LoginForm`'s markup); "Forgot password?" link added to `LoginForm`'s credentials step. README §4 (Resend port rationale), §6 (reset + email flow diagram), §7 (`/auth` table + example payloads), §8 (routes table), §9 (new "Password reset tokens" subsection + controls table rows), §12 (M-65/M-67 now `unimplemented`, web built), §14 (Built-and-working rows, Suggested next steps), §15 (new env vars), §16 (built vs next) updated in this PR. Status: **Testing**. Handoff: Tester. |
| 2026-08-15 | Tester | TR-S-035 filed — 7/7 AC pass (6 fully automated, AC 5 automated + a manual code-review checklist item for the "no marketing UI" half). 54 new backend pytest tests (`test_password_reset.py`, `test_email_provider.py`, `test_email_templates.py`, `test_forgot_reset_password.py`, `test_transactional_email_side_effects.py`) + 11 new/changed frontend RTL/Jest tests; zero regressions in the existing 214-test backend baseline or 96-test frontend suite. Found and fixed one pre-existing **test-only** fixture gap (`test_businesses_cache_invalidation.py`'s local `FakeResult` was missing `scalar_one_or_none()`, which `approve_business`'s new Merchant lookup now calls) — not a product-code defect. Per the same live-Postgres/no-local-Redis environment constraint already flagged in `TR-S-018`, all S-035 tests use direct-function-call + fake-db/fake-Redis coverage rather than ASGI + real DB, to avoid further writes to the shared live database; flagged as a gap, not a blocker. One negligible code-inspection note (unchecked `nx=True` return in `create_reset_token`, ~1-in-2^256 collision risk) — not a blocker. Recommendation: **Ship**. |
| 2026-08-15 | PM | Reviewed TR-S-035 against AC as written, plus independent code read of `auth.py` (forgot/reset routes), `password_reset.py`, `services/email/{__init__,templates}.py`, `businesses.py::approve_business`, `reviews.py::create_review`, the new frontend `/forgot-password` and `/reset-password` pages, and the README §4/§6/§7/§8/§9/§12 sections cited in the Builder changelog — all confirmed accurate, not just the report's claims. All 7 AC hold up: mock-only/no-network + best-effort send (AC1), byte-identical generic response incl. Google-only and Redis-down-before-lookup (AC2), APPROVAL notification + email (AC3), REVIEW notification + email to owner not reviewer (AC4), no marketing/subscribe UI (AC5), offline mock round trip (AC6), no AI text in any template body (AC7). Gaps noted by Tester (no live Docker/real-DB round trip, M-002/M-003 not run live, unchecked Redis `nx` return) are non-blocking per the same `TR-S-018`-class environment constraint already accepted for other slices, and the `nx` note is a ~1-in-2^256 theoretical concern, not exploitable. DoD fully satisfied. Status: **Accepted**. |
