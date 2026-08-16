# TP-S-049: AI topic clustering for merchant reviews — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-049 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

New `GET /api/v1/ai/businesses/{business_id}/topics` endpoint (RBAC via
`require_roles(MERCHANT, ADMIN)` + ownership, eligibility gate on `ai_topics_min_reviews`/
`ai_topics_min_review_chars`, Redis cache-aside, graceful degrade-to-mock and
unavailable-on-error handling); the new `Operation.TOPIC_CLUSTERING` / `TopicClusterResult` /
`coerce_topic_sentiment` additions to `app/services/ai/base.py`; `MockAIProvider.
generate_topic_clusters`; and the frontend "Common Themes" section added to `AIInsights.tsx`
(fed by `MerchantDashboard.tsx` via `dashboard.topics()`). See the slice's 7 numbered AC and
Architect technical specification for full contract.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend unit | pytest, no DB | `coerce_topic_sentiment` domain coercion (AC2 support), `MockAIProvider.generate_topic_clusters` shape |
| Backend API (RBAC + router logic) | pytest, fake db/provider objects, direct route-handler calls | 401/403/ownership (AC5), admin parity (AC6), eligibility gate + zero-LLM-call proof (AC4), happy path (AC1) incl. count-descending ordering, degraded-to-mock (AC3) and provider-errors-outright (AC7) via `monkeypatch` on `app.routers.ai.get_ai_provider` |
| Frontend | Jest + RTL | `AIInsights.tsx` "Common Themes" section: topic list rendering + suggestion/sentiment labeling (AC2), insufficient-data empty state (AC4), unavailable message (AC7), degraded prefix (AC3) |
| Manual | Docker smoke / code review | Full dashboard load with a real business, admin equivalent view, Swagger `/docs` route shape |

`AI_PROVIDER=mock` / `AI_FALLBACK_PROVIDER=mock` per `backend/.env` — the default path in this
environment already exercises the mock provider directly (not a fallback), so AC3's degraded
path is exercised by explicitly monkeypatching a failing primary + mock fallback through
`AIGateway`, matching the pattern in `test_ai_gateway.py`.

**Revised from the original plan of ASGI + real-Postgres tests (`test_dashboard.py`'s pattern):**
an initial attempt at that approach reproduced the known connection-pool-contention flake
(`InterfaceError: cannot perform operation: another operation is in progress`) — and, more
seriously, cross-request bind-parameter corruption on a plain `PATCH /auth/me` — on the very
first two-registration test, consistently, even run in complete process isolation. That proves
this isn't limited to "48 unrelated tests in the mega-suite"; it also hits small, targeted,
DB-heavy ASGI suites locally against the remote Railway proxy DB. Per the Builder's note this is
not chased/fixed here — `test_ai_topics.py` instead follows `test_reviews.py` /
`test_admin_browse.py`'s established fake-db, direct-handler-call convention, which needs no
real Postgres connection at all. No local Redis is reachable either (`cache_get`/`cache_set`
fail open, confirmed empirically — no listener on 6379); the test file pins both to an explicit
deterministic no-op via `monkeypatch` rather than relying on that fail-open behavior implicitly.
Cache-hit behavior itself is not separately exercised (out of the 7 numbered AC).

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. Eligible business renders named topics with count + sentiment, ordered by count descending | Automated | `test_ai_topics.py::TestHappyPath::test_topics_render_for_eligible_business_with_shape`, `::test_topics_are_ordered_by_count_descending` |
| 2. Every topic labeled as a suggestion; panel disclaimer continues to cover the section | Automated (frontend) | `AIInsights.test.tsx::"renders each topic with count, sentiment, and a (suggestion) label"` |
| 3. Fallback-to-mock still renders topics, surfaced as degraded ("Mock/degraded data." prefix) | Automated | Backend: `test_ai_topics.py::TestDegradedAndUnavailable::test_falls_back_to_mock_and_reports_degraded`; Frontend: `AIInsights.test.tsx::"prefixes each topic with 'Mock/degraded data.' when topics_degraded is true"` |
| 4. Too-few/too-short reviews → plain-language empty state, no AI call made | Automated | Backend: `test_ai_topics.py::TestEligibilityGate::test_insufficient_data_when_below_threshold`, `::test_provider_never_called_when_below_threshold`; Frontend: `AIInsights.test.tsx::"renders the insufficient-data empty state and no topic list"` |
| 5. Customer / unauthenticated rejected; merchant restricted to own business | Automated | `test_ai_topics.py::TestRBAC::test_401_unauthenticated`, `::test_403_customer_role`, `::test_403_non_owning_merchant` |
| 6. Admin sees same topic data as the owning merchant | Automated | `test_ai_topics.py::TestAdminParity::test_admin_sees_same_topics_as_owning_merchant` |
| 7. Provider errors outright → graceful "temporarily unavailable", never a 5xx | Automated | Backend: `test_ai_topics.py::TestDegradedAndUnavailable::test_provider_error_returns_unavailable_not_5xx`; Frontend: `AIInsights.test.tsx::"renders the unavailable message when topics_unavailable is true"` |

Additional (non-AC, contract) coverage:
- `test_ai_topics.py::TestCoerceTopicSentiment` (co-located in `test_ai_contract.py`) —
  `coerce_topic_sentiment` never raises, maps free-form model output onto the 3-value domain.
- `test_ai_topics.py::TestNotFound::test_404_for_missing_business` — response-contract sanity,
  not a numbered AC.

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| `GET /ai/businesses/{id}/topics` | anonymous | 401 |
| `GET /ai/businesses/{id}/topics` | customer | 403 |
| `GET /ai/businesses/{id}/topics` | merchant, not owning `{id}` | 403 |
| `GET /ai/businesses/{id}/topics` | merchant, owns `{id}` | 200 |
| `GET /ai/businesses/{id}/topics` | admin, any business | 200 |

---

## Edge cases

- Business below `ai_topics_min_reviews` (0 or a few short/none-eligible reviews) — `insufficient_data=True`,
  zero calls to `get_ai_provider` (spy-verified).
- Mock provider's keyword-bucket clustering is **not** sorted by count in the current
  implementation (neither the router nor `MockAIProvider.generate_topic_clusters` sorts) —
  explicitly tested against AC1's "ordered by count descending" wording; see test report for
  the pass/fail outcome and any recommended fix.
- Provider raises after being wrapped in `AIGateway` (primary fails, fallback/mock succeeds) vs.
  provider raises directly with no gateway wrapping (simulates "both primary and fallback
  failed" collapsing to `unavailable=True`) — both paths exercised separately (AC3 vs AC7).
- Missing business → `404` (not one of the 7 AC, but part of the documented API contract).

---

## Manual checklist (if applicable)

- [ ] M-001: `docker compose up --build`; sign in as a merchant with an approved business and
  ≥5 substantive reviews, confirm "Common Themes" renders on `/merchant/dashboard`.
- [ ] M-002: Same business, sign in as admin (admin-facing dashboard equivalent, if reachable),
  confirm the same topics render.
- [ ] M-003: Swagger `/docs` — confirm `GET /ai/businesses/{business_id}/topics` matches the
  implemented route/response shape (`TopicClusterResponse`).

Not executed this pass (no Docker session available here); flagged for PM/Builder to run
before final acceptance, consistent with prior slices in this environment.

---

## Environment

- `AI_PROVIDER=mock`, `AI_FALLBACK_PROVIDER=mock` (`backend/.env`) — no live LLM calls.
- Backend tests run via `./.venv/Scripts/python.exe -m pytest` (not bare `python`), targeted at
  the new/AI-related files only — the full `pytest -q --ignore=tests/e2e` mega-suite has a known
  pre-existing, unrelated flaky failure pattern against the remote Railway Postgres proxy under
  connection-pool contention; not chased here.
- `cd frontend && npm test` for RTL coverage.
