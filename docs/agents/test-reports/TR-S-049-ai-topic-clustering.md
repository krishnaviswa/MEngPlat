# TR-S-049: AI topic clustering for merchant reviews — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-049 |
| **Author** | Tester |
| **Date** | 2026-08-16 |
| **Recommendation** | Rework (1 blocker) |

---

## Summary

6 of 7 AC pass fully and are automated. AC 1 is **partially** unmet: eligible topics render
correctly with the right label/count/sentiment/example-quote shape (the first clause of AC1),
but the second clause — "**ordered by count descending**" — is **not implemented**. Neither
`get_topic_clusters` (`backend/app/routers/ai.py`) nor `MockAIProvider.generate_topic_clusters`
(`backend/app/services/ai/providers/mock.py`) sorts the topic list; the mock provider emits
topics in a fixed keyword-bucket-definition order (Service speed → Staff friendliness →
Cleanliness → Value for money) regardless of each bucket's actual match count, and nothing
downstream re-sorts. A new automated test
(`test_ai_topics.py::TestHappyPath::test_topics_are_ordered_by_count_descending`) reproduces
this deterministically: a business with 4 "Value for money" mentions and 1 "Staff friendliness"
mention returns `[Staff friendliness (1), Value for money (4)]`, not descending. Real (non-mock)
providers are only ever *prompted* to order by count ("Return JSON: topics (array of
{label, count, sentiment, example_quote})" — the `TOPIC_CLUSTERING_SYSTEM` prompt has no explicit
ordering instruction, and even if it did, LLM output ordering isn't a guarantee any code path
enforces) — so this isn't mock-only cosmetics, it's a real gap against the AC as written for
every provider. **Fix is small and localized**: sort `cluster_result.topics` by `count` descending
in `get_topic_clusters` right before building `payload` (one line, defends every provider
uniformly, no schema/contract change) — this is the recommended rework, not a redesign.

Every other AC passes: eligible-business rendering + shape (AC1's first clause), suggestion
labeling on every topic + disclaimer still covers the section (AC2, frontend), degrade-to-mock
with the "Mock/degraded data." prefix (AC3), the eligibility gate short-circuits **before** any
AI provider call with zero calls made (AC4), full RBAC incl. 401/403/ownership (AC5), admin sees
identical topic data to the owning merchant (AC6), and a provider erroring outright degrades to
`unavailable=True` with a 200, never a 5xx, and is never cached (AC7).

One regression was found and fixed during this pass, not a slice AC but blocking a clean test
run: `frontend/src/components/__tests__/MerchantDashboard.test.tsx`'s shared `dashboard` jest
mock did not include `topics`, so `MerchantDashboard.tsx`'s new `dashboard.topics(b.id)` call
threw synchronously in every test using that mock (`dashboard.topics is not a function`) — the
throw happens before `.catch(() => null)` can attach, so it propagated past the outer
`loadBusiness(b).catch(() => setInsights(null))` and silently nulled out `insights` entirely,
breaking the pre-existing "labels AI monthly_trends as a suggestion and flags degraded data"
test. Fixed by adding `topics: jest.fn()` to the mock (default-resolved to `null` in every
`beforeEach`, matching the existing `insightsMock` convention) — see Regressions/gaps below.

Both new backend AI-provider abstractions (`coerce_topic_sentiment`, `MockAIProvider.
generate_topic_clusters`, the `AIGateway`/router degrade/unavailable wiring) behave correctly
and defensively (never raises, never surfaces a raw error to the caller).

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Eligible business renders named topics with count + sentiment indicator, ordered by count descending | A | Shape/counts: `backend/tests/test_ai_topics.py::TestHappyPath::test_topics_render_with_expected_shape_and_counts` (Pass). Ordering: `TestHappyPath::test_topics_are_ordered_by_count_descending` (**Fail — see Summary/Gaps**) | **Fail** (partial — rendering/shape correct, count-descending ordering not implemented) |
| 2 | Every topic labeled as a suggestion; panel's top-level disclaimer continues to cover the section | A | `frontend/src/components/__tests__/AIInsights.test.tsx::"renders each topic with a label, count, sentiment, and a (suggestion) label (AC1/AC2)"`, `::"continues to show the panel's top-level disclaimer alongside topics (AC2)"` | Pass |
| 3 | Fallback-to-mock still renders topics, surfaced as degraded ("Mock/degraded data." prefix) | A | Backend: `test_ai_topics.py::TestDegradedAndUnavailable::test_falls_back_to_mock_and_reports_degraded`. Frontend: `AIInsights.test.tsx::"prefixes each topic with 'Mock/degraded data.' when topics_degraded is true (AC3)"`, `::"does not prefix topics with the degraded label when topics_degraded is false/absent"` | Pass |
| 4 | Too-few/too-short reviews → plain-language empty state, not an empty list/spinner/error; no AI call made | A | Backend: `test_ai_topics.py::TestEligibilityGate::test_insufficient_data_when_below_threshold` (also asserts only 2 `db.execute` calls — no reviews+analysis fetch), `::test_provider_never_called_when_below_threshold` (spies on `get_ai_provider`, asserts zero calls). Frontend: `AIInsights.test.tsx::"renders the insufficient-data empty state and no topic list (AC4)"` | Pass |
| 5 | Customer/unauthenticated rejected; merchant restricted to own business | A | `test_ai_topics.py::TestRBAC::test_401_unauthenticated`, `::test_403_customer_role`, `::test_403_non_owning_merchant` | Pass |
| 6 | Admin sees same topic data as the owning merchant | A | `test_ai_topics.py::TestAdminParity::test_admin_sees_same_topics_as_owning_merchant` (also asserts admin skips the Merchant-ownership `db.execute` call entirely — only 2 calls vs. the merchant's 3) | Pass |
| 7 | Provider errors outright → graceful "temporarily unavailable" message, never a 5xx | A | Backend: `test_ai_topics.py::TestDegradedAndUnavailable::test_provider_error_returns_unavailable_not_5xx` (also asserts the failed result is never cached). Frontend: `AIInsights.test.tsx::"renders the unavailable message when topics_unavailable is true, not a crash or raw error (AC7)"` | Pass |

Additional (non-AC) coverage:
- `backend/tests/test_ai_contract.py::TestCoerceTopicSentiment` — `coerce_topic_sentiment` never
  raises, maps free-form model output onto the `positive|negative|mixed` domain, defaults to
  `"mixed"` (not `"neutral"`) for ambiguous/unrecognized input. Pass (23 parametrized cases).
- `test_ai_topics.py::TestNotFound::test_404_for_missing_business` — Pass.

---

## Backend tests added

- `backend/tests/test_ai_topics.py` (new file, 11 tests):
  - `TestRBAC::test_401_unauthenticated`
  - `TestRBAC::test_403_customer_role`
  - `TestRBAC::test_403_non_owning_merchant`
  - `TestNotFound::test_404_for_missing_business`
  - `TestEligibilityGate::test_insufficient_data_when_below_threshold`
  - `TestEligibilityGate::test_provider_never_called_when_below_threshold`
  - `TestHappyPath::test_topics_render_with_expected_shape_and_counts`
  - `TestHappyPath::test_topics_are_ordered_by_count_descending` (**fails — real gap, see Summary**)
  - `TestAdminParity::test_admin_sees_same_topics_as_owning_merchant`
  - `TestDegradedAndUnavailable::test_falls_back_to_mock_and_reports_degraded`
  - `TestDegradedAndUnavailable::test_provider_error_returns_unavailable_not_5xx`
- `backend/tests/test_ai_contract.py::TestCoerceTopicSentiment` (new class, 2 parametrized tests
  covering 23 cases total, added alongside the existing `TestCoerceSentiment`)

**Design note (environment-driven):** `test_ai_topics.py` was originally planned as ASGI +
real-Postgres tests (`test_dashboard.py`'s pattern, per the task brief). An initial attempt at
that reproduced the known connection-pool-contention flake
(`InterfaceError: cannot perform operation: another operation is in progress`) — and, worse,
cross-request bind-parameter corruption on a plain `PATCH /auth/me` (`'PAN'` bound where `'pan'`
was sent) — on the very first two-registration test, consistently, even run in complete process
isolation. That proves the flakiness the task brief warned about (previously observed only across
"~48 unrelated tests" in the full mega-suite) also hits small, targeted, DB-heavy ASGI suites
locally against the remote Railway proxy DB. Per the Builder's note this is not chased/fixed here
— the file was rewritten to follow `test_reviews.py`/`test_admin_browse.py`'s established
fake-db, direct-handler-call convention instead, which needs no real Postgres connection. RBAC
tests call the exact same `require_roles(...)`/`get_current_user` dependency factories the router
declares (same technique as `test_admin_browse.py::TestAdminBrowseRBAC`); router-logic tests use
a `ScriptedDB` that returns `db.execute()` results in the router's own known call order (same
scripted-sequence idea as `test_ai_gateway.py`'s `FakeProvider`, applied to `db.execute` instead
of provider calls) rather than generically emulating SQLAlchemy's `func.count`/`join` compilation.
`cache_get`/`cache_set` are explicitly monkeypatched to a deterministic no-op (no local Redis is
reachable in this environment either — confirmed empirically, no listener on 6379 — so this pins
behavior rather than relying on fail-open).

Verified together, no regressions: `pytest tests/test_ai_topics.py tests/test_ai_contract.py
tests/test_ai_gateway.py tests/test_ai_registry.py tests/test_ai_anthropic.py
tests/test_ai_openai_family.py tests/test_ai_provider_config.py
tests/test_ai_startup_validation.py tests/test_business_service_summary.py -q` →
**120 passed, 1 failed** (the ordering gap above), ~9s. Full mega-suite not run locally, per the
Builder's note on the pre-existing unrelated flaky pattern under this environment's DB proxy.

---

## Frontend tests added

- `frontend/src/components/__tests__/AIInsights.test.tsx` (new file, 7 tests):
  - `"renders each topic with a label, count, sentiment, and a (suggestion) label (AC1/AC2)"`
  - `"continues to show the panel's top-level disclaimer alongside topics (AC2)"`
  - `"renders the insufficient-data empty state and no topic list (AC4)"`
  - `"renders the unavailable message when topics_unavailable is true, not a crash or raw error (AC7)"`
  - `"prefixes each topic with 'Mock/degraded data.' when topics_degraded is true (AC3)"`
  - `"does not prefix topics with the degraded label when topics_degraded is false/absent"`
  - `"renders no Common Themes section at all when topics data hasn't loaded (no relevant fields set)"`

All 7 pass.

**Regression fixed (not a slice AC):** `frontend/src/components/__tests__/MerchantDashboard.
test.tsx`'s shared `jest.mock("../../lib/api", ...)` for `dashboard` was missing `topics`.
`MerchantDashboard.tsx`'s new `dashboard.topics(b.id).catch(() => null)` call threw synchronously
against the undefined mock method (before `.catch` could attach), which the outer
`loadBusiness(b).catch(() => setInsights(null))` swallowed — silently nulling `insights` in every
test using that shared mock and breaking the pre-existing `"labels AI monthly_trends as a
suggestion and flags degraded data"` test (S-033). Fixed by adding `topics: jest.fn()` to the
mock and `topicsMock.mockResolvedValue(null)` to each of the file's 4 `beforeEach` blocks,
matching the existing `insightsMock` convention. Confirmed green after the fix.

Full suite: `npm test` → **36 suites / 168 tests passed**, 0 failed, no other regressions.

---

## Manual checklist

- [ ] M-001: `docker compose up --build`; sign in as a merchant with an approved business and
  ≥5 substantive reviews, confirm "Common Themes" renders on `/merchant/dashboard`. **Not run**
  this pass (no Docker session available here).
- [ ] M-002: Same business, sign in as admin, confirm the same topics render. **Not run.**
- [ ] M-003: Swagger `/docs` — confirm `GET /ai/businesses/{business_id}/topics` matches the
  implemented route/response shape. **Not run** — spot-checked instead by reading
  `app/routers/ai.py` + `app/schemas/__init__.py` directly; shapes match the Architect's contract
  exactly (`TopicClusterResponse` fields, `require_roles(MERCHANT, ADMIN)` + ownership).

Flagged for PM/Builder to execute before final acceptance, consistent with prior slices in this
environment.

---

## Regressions / gaps

1. **AC1 ordering — Fail, blocker.** Topics are not sorted by count descending anywhere in the
   pipeline (`get_topic_clusters` router function, `MockAIProvider.generate_topic_clusters`, or
   the `TopicClusterResponse`/`TopicItem` schema layer). Reproduced deterministically in
   `test_ai_topics.py::TestHappyPath::test_topics_are_ordered_by_count_descending`.
   **Recommended fix:** in `backend/app/routers/ai.py::get_topic_clusters`, sort
   `cluster_result.topics` by `count` descending immediately after the provider call succeeds,
   before building `payload` — e.g. `topics = sorted(cluster_result.topics, key=lambda t:
   t.get("count", 0), reverse=True)`. This is provider-agnostic (protects real LLM output too,
   which has no code-enforced ordering guarantee despite the prompt asking for themes, not an
   explicit order) and requires no schema change.
2. **MerchantDashboard.test.tsx mock gap — Fixed in this pass, not a slice AC.** See Frontend
   tests added, above. Flagging here for visibility since it was a real regression against
   already-`Accepted` S-033 coverage, caused by this slice's frontend wiring change.

No other bugs or gaps found. RBAC is fully enforced (401/403/ownership) and verified DB-free;
the AI disclaimer/suggestion language is correct on every topic and the section as a whole;
degrade-to-mock and provider-error paths both degrade gracefully with the exact wording specified
in the slice's UX notes.

---

## Recommendation

**Rework** (1 blocker): fix AC1's count-descending ordering (see Gaps §1 — small, localized,
provider-agnostic fix) and re-run `test_ai_topics.py::TestHappyPath::
test_topics_are_ordered_by_count_descending` to confirm, then this slice is ready for PM
acceptance. Everything else (AC2–AC7, both new test files, the MerchantDashboard mock
regression) is green with no further action needed.

---

## PM post-fix verification (2026-08-16)

Applied the Tester's recommended fix exactly as specified: `backend/app/routers/ai.py::
get_topic_clusters` now sorts `cluster_result.topics` by `count` descending before building
`payload` (and before caching), so the fix protects real providers too, not just mock.

Re-ran:
- `pytest tests/test_ai_topics.py -q` → **11/11 passed**, including
  `TestHappyPath::test_topics_are_ordered_by_count_descending`.
- `pytest tests/test_ai_gateway.py tests/test_ai_contract.py tests/test_ai_registry.py
  tests/test_ai_anthropic.py tests/test_business_service_summary.py tests/test_ai_topics.py -q`
  → **97/97 passed**, no regressions.
- `npm test -- --watchAll=false` (frontend) → **36 suites / 168 tests passed**, no regressions.

All 7 AC now pass. **Updated recommendation: Accepted.**
