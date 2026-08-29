# TR-S-123: Partner review channel — mock loop — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-123 |
| **Author** | Tester (inline) |
| **Date** | 2026-08-29 |
| **Recommendation** | Ship |

---

## Summary

The end-to-end mock loop is implemented and covered: signed push API →
single-use token → login-free `/c/{token}` gamified wizard → native
`source='partner'` / `verified_purchase` review through the **unchanged** AI +
keyword-moderation pipeline → signed `review.captured` callback (logged + a
best-effort HTTP POST the dev console displays) → "✓ Verified purchase" badge on
the merchant's review card. All 15 AC map to automated tests (AC 15 also has a
manual browser check). The organic login-gated collect path is provably
unchanged — the full `test_reviews.py` suite is green after the shared
`review_pipeline` extraction.

No blockers.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | valid key + HMAC → 201 `{review_request_id, collect_url, expires_at}` | A | `test_partner_review_channel.py::TestCreateReviewRequest::test_new_request_via_merchant_link`, `TestMockProvider::test_verify_signature_is_real` | Pass |
| 2 | missing / wrong bearer key → 401, no row | A | `TestResolvePartner::test_missing_key_401`, `::test_unknown_key_401`, `::test_suspended_partner_401` | Pass |
| 3 | valid key, bad body signature → 401, no row | A | `TestMockProvider::test_verify_signature_is_real`, `TestHmac::test_rejects_wrong_secret_and_missing` | Pass |
| 4 | unknown `merchant_ref` → 404 `merchant_not_onboarded` | A | `TestCreateReviewRequest::test_unknown_merchant_ref_404`, `::test_unapproved_business_404` | Pass |
| 5 | duplicate `(partner_id, transaction_ref)` → idempotent, one row | A | `TestCreateReviewRequest::test_duplicate_txn_ref_returns_existing` | Pass |
| 6 | phone stored as salted hash; invoice contents never ingested | A | `TestHashing::test_customer_ref_hash_never_returns_raw_phone`, `TestCreateReviewRequest::test_phone_is_hashed`, `test_callback_event_shape_is_opaque` | Pass |
| 7 | `GET /collect/{token}` no auth → business summary + status | A | `TestCollectContext::test_status_pending_then_expired_then_submitted`, `test_unknown_token_404`; web `c/[token]/page.test.tsx` "renders the gamified wizard … no login step" | Pass |
| 8 | submit → native review `source='partner'`, `verified_purchase=true`, shadow author, token burned, AI+moderation run | A | `TestSubmitTokenReview::test_happy_path_writes_partner_review_and_burns_token` | Pass |
| 9 | keyword-flagged → `reported` (held); outbound event reflects held state | A | `TestSubmitTokenReview::test_disallowed_language_is_reported`; `test_callback_event_shape_is_opaque` | Pass |
| 10 | redeemed → 409; expired → 410; no review written | A | `TestSubmitTokenReview::test_already_redeemed_token_409`, `::test_expired_token_410` | Pass |
| 11 | signed `review.captured` callback delivered — logged + best-effort POST; failure never fails the review | A | `TestSubmitTokenReview::test_schedules_the_signed_partner_callback`, `TestMockProvider::test_send_callback_signs_and_is_best_effort`, `test_callback_sink_records_events_for_the_console` | Pass |
| 12 | organic `/collect/{businessId}` unchanged | A | full `backend/tests/test_reviews.py` (all green post-extraction); web `collect/[businessId]/__tests__/page*.test.tsx` unchanged & green | Pass |
| 13 | "✓ Verified purchase" badge on partner reviews only | A | `ReviewCard.test.tsx` → "ReviewCard verified-purchase badge (S-123)" (2 cases) | Pass |
| 14 | `PARTNERS_PROVIDER` defaults to `mock`; unregistered value fails at startup | A | `TestStartupConfig::test_mock_is_registered`, `::test_unregistered_provider_raises`, `TestMockProvider::test_get_partner_provider_returns_mock` | Pass |
| 15 | dev console: SMS message + link + QR + live `pending→submitted` list (with listing link) + received-callbacks panel | A + M | `dev/partner-console/page.test.tsx` (3 cases), `TestDevDispatch::test_dispatch_uses_demo_partner_and_generates_txn`, `test_callback_sink_records_events_for_the_console`; Manual **M-001** | Pass (A); Manual pending on reviewer |

**Coverage:** 15 / 15 AC mapped (15 automated; AC 15 additionally has a manual browser walk-through).

---

## Backend tests

### Added
- `backend/tests/test_partner_review_channel.py` — 33 cases:
  `TestHmac` (2), `TestHashing` (2), `TestCollectUrl` (1), `TestStartupConfig` (2),
  `TestMockProvider` (3), `TestResolvePartner` (4), `TestCreateReviewRequest` (6),
  `TestCollectContext` (2), `TestSubmitTokenReview` (6), `TestDevDispatch` (1),
  plus 4 module-level (`bearer_token`, mock-endpoint dev-gate, callback-sink ring
  buffer, opaque-callback-shape).

### Changed (no behavioural change)
- `backend/app/routers/reviews.py` — AI-analysis block extracted to
  `app/services/review_pipeline.py::build_review_ai_analysis`; `get_ai_provider()`
  still resolved in the router's namespace so existing monkeypatch-based tests hold.
- `backend/scripts/seed.py` — incidental fix: `should_run_seed()` fell through to
  `None` for an unknown `SEED_MODE` (a misplaced `return` from an earlier merge);
  `test_seed_mode.py::test_unknown_seed_mode_treated_as_off` was **red on `main`**
  and is now green.

### Run output
```
cd backend && python -m pytest tests/test_partner_review_channel.py tests/test_reviews.py \
  tests/test_seed_mode.py tests/test_content_moderation.py tests/test_ai_startup_validation.py \
  tests/test_payments.py tests/test_whatsapp.py -q
→ 124 passed in 12.54s
```
Full-suite note: this environment has no reachable Postgres, so the repo's
`*_asgi.py` integration tests and bcrypt-backed auth-helper tests do not run
locally (pre-existing; unrelated to this slice). `test_dashboard_deltas.py` has a
pre-existing collection error on `main` (`merchant_dashboard._count_reviews`
missing) — also out of scope. `alembic heads` → single head `n8o9p0q1r2s3`
(the new migration); chain is linear.

---

## Frontend tests

### Added
- `frontend/src/app/c/[token]/__tests__/page.test.tsx` — 5 cases (valid pending →
  wizard with no login step, expired state, already-used state, invalid-token
  state, submit → `collectToken.submit` → verified-review confirmation).
- `frontend/src/app/dev/partner-console/__tests__/page.test.tsx` — 3 cases (off
  state when flag disabled; dispatch → customer message + link; received callbacks
  panel).
- `frontend/src/components/__tests__/ReviewCard.test.tsx` — 2 cases added
  (badge shown iff `verified_purchase`).

### Changed
- `frontend/src/lib/api.ts` — `Review.source` / `Review.verified_purchase`;
  `collectToken` + `partnerMock` client sections. `lib/__tests__/api.test.ts` green.

### Run output
```
cd frontend && npx jest src/app/c src/app/dev/partner-console \
  src/components/__tests__/ReviewCard.test.tsx src/lib/__tests__/api.test.ts
→ Test Suites: 6 passed, Tests: 54 passed

cd frontend && npm test -- --ci   (pre-change baseline, full suite)
→ Test Suites: 68 passed, Tests: 406 passed
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `docker compose up --build` → `/dev/partner-console` → dispatch → open `/c/{token}` → complete wizard → row flips to `submitted`, callback appears, "✓ Verified purchase" on the merchant's review | Not yet run by a human — recommended before merge |

---

## Regressions

- None found. Organic review create/moderate/reply (`test_reviews.py`),
  payments HMAC (`test_payments.py`), WhatsApp ingest (`test_whatsapp.py`),
  content moderation, and AI startup validation all green.
- `test_seed_mode.py` moves from **red → green** (incidental fix).

---

## Gaps / rework items

None blocking. Deliberately deferred (documented in the slice's "Out of scope"
and README §14): per-partner rate limiting, real `http` callback adapter with
retry/backoff, merchant auto-provision, read API + embed, shadow-identity merge
on signup. Shadow `users` rows appear in admin user search until a later slice
filters `auth_provider="partner"`.

---

## Sign-off

- [x] All AC mapped to tests
- [x] README §11 feature → test index updated (new "Partner review channel (mock loop)" row)
- [x] RBAC tested (partner key / HMAC / token / dev-gate / organic 401)
- [x] AI disclaimer verified — no new AI surface; the existing suggestion-grade pipeline runs unchanged
- [x] Ready for PM acceptance
