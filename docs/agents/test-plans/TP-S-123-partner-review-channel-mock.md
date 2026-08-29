# TP-S-123: Partner review channel — mock loop — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-123 |
| **Author** | Tester (inline) |
| **Date** | 2026-08-29 |

---

## Scope

The end-to-end partner-review mock loop: the signed push API, the login-free
`/c/{token}` collect path, the `PARTNERS_PROVIDER=mock` port, the dev billing
console, and the "verified purchase" badge. Also: proof the **organic** collect
path is unchanged after the shared-AI-pipeline extraction.

Out of scope for testing (not built): real partner onboarding, read API, embed,
rate limiting, auto-provision.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend service/router | pytest (unit-style, `FakeDB` — no real DB in this env) | HMAC auth, token lifecycle, dedupe, shadow identity, moderation branch, callback scheduling, dev-gating |
| Backend pure helpers | pytest | `hmac_util`, key/phone hashing, `collect_url`, startup config |
| Frontend | Jest + RTL | `/c/[token]` phases + submit, mock console dispatch + callbacks panel, `ReviewCard` badge, `api.ts` client shape |
| Integration | Manual | `docker compose up` → click the full loop in the browser |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 valid key + HMAC → 201 collect_url | Automated | `test_partner_review_channel.py::TestCreateReviewRequest::test_new_request_via_merchant_link` + `TestMockProvider::test_verify_signature_is_real` |
| 2 missing/wrong key → 401, no row | Automated | `TestResolvePartner::test_missing_key_401`, `test_unknown_key_401` |
| 3 bad body signature → 401, no row | Automated | `TestMockProvider::test_verify_signature_is_real`; `TestHmac::test_rejects_wrong_secret_and_missing` |
| 4 unknown merchant_ref → 404 `merchant_not_onboarded` | Automated | `TestCreateReviewRequest::test_unknown_merchant_ref_404`, `test_unapproved_business_404` |
| 5 duplicate `(partner, txn_ref)` → idempotent | Automated | `TestCreateReviewRequest::test_duplicate_txn_ref_returns_existing` |
| 6 phone hashed, no invoice contents | Automated | `TestHashing::test_customer_ref_hash_never_returns_raw_phone`, `TestCreateReviewRequest::test_phone_is_hashed`, `test_callback_event_shape_is_opaque` |
| 7 `GET /collect/{token}` no auth → business + status | Automated | `TestCollectContext::test_status_pending_then_expired_then_submitted`; web `page.test.tsx` "renders the gamified wizard" |
| 8 submit → native review `source=partner` / `verified_purchase`, token burned, pipeline runs | Automated | `TestSubmitTokenReview::test_happy_path_writes_partner_review_and_burns_token` |
| 9 keyword-flagged → `reported`, event reflects held | Automated | `TestSubmitTokenReview::test_disallowed_language_is_reported`; `test_callback_event_shape_is_opaque` (status field) |
| 10 redeemed/expired token → 409 / 410 | Automated | `TestSubmitTokenReview::test_expired_token_410`, `test_already_redeemed_token_409` |
| 11 signed `review.captured` callback delivered (logged + best-effort POST) | Automated | `TestSubmitTokenReview::test_schedules_the_signed_partner_callback`, `TestMockProvider::test_send_callback_signs_and_is_best_effort`, `test_callback_sink_records_events_for_the_console` |
| 12 organic path unchanged | Automated | full `test_reviews.py` green after the `review_pipeline` extraction |
| 13 verified-purchase badge | Automated | `ReviewCard.test.tsx` "verified-purchase badge (S-123)" |
| 14 `PARTNERS_PROVIDER` defaults to mock; junk fails startup | Automated | `TestStartupConfig::*`, `TestMockProvider::test_get_partner_provider_returns_mock` |
| 15 dev console: message + link + QR + live list + callbacks panel | Automated + Manual | `dev/partner-console/page.test.tsx`; `TestDevDispatch`; Manual M-001 |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| `POST /partner/review-requests` no bearer | anonymous | 401 |
| `POST /partner/review-requests` wrong key | anonymous | 401 |
| `POST /partner/review-requests` valid key, bad signature | partner | 401 |
| `GET/POST /collect/{token}` valid token | anonymous | 200 / 201 |
| `POST /collect/{token}` redeemed / expired | anonymous | 409 / 410 |
| `/partner-mock/*` when `debug=false` | anyone | 404 |
| organic `POST /reviews` unauthenticated | anonymous | 401 (unchanged) |

---

## Edge cases

- Concurrent duplicate `transaction_ref` → `IntegrityError` caught, existing row returned.
- Repeat customer (same phone hash, same business) → shadow user reused → `UNIQUE(author_id, business_id)` → 409.
- No phone on the request → fresh anonymous shadow user per request.
- Callback URL unreachable → warning logged, review still succeeds.

---

## Manual checklist

- [ ] M-001: `docker compose up --build`; open `/dev/partner-console`; pick Sunrise Corner Café; Send review request; confirm the SMS message + link + QR render; open the link; complete the gamified wizard; confirm "verified review is live"; back in the console the row flips to `submitted` and a `review.captured` callback appears; open the business listing as the merchant and confirm the "✓ Verified purchase" badge.

---

## Environment

- `AI_PROVIDER=mock`, `PARTNERS_PROVIDER=mock`, `DEBUG=true`, `NEXT_PUBLIC_ENABLE_PARTNER_MOCK=true`
- `docker compose up --build` (or `pytest` / `npm test` for the automated layers)
