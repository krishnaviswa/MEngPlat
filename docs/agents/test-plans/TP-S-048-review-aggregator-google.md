# TP-S-048: Multi-platform review aggregator foundation (Google Places) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-048 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

Merchant-triggered Google Places search, one-time Place ID link, on-demand
review sync (up to 5 most-relevant reviews), public "Also reviewed on Google"
read, and the mock review-source provider used whenever `GOOGLE_PLACES_API_KEY`
is unset. Covers the 16 numbered AC and the Architect API/RBAC/data-model
contract. Real Google Places smoke is **out of this plan's automated layer**
until a billing-enabled key exists (slice pre-condition).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest, ASGI + real test DB (`test_google_reviews.py`, same pattern as `test_dashboard.py`) | Search/link/sync/public read, RBAC, idempotent upsert, debounce lock, native rating isolation, mock provider |
| Backend unit | pytest, no network | `get_review_source_provider()` selects `mock` when the key is empty (AC16) |
| Frontend | Jest + RTL | `GooglePlacePicker` (AC1–5), `ExternalReviews` (AC10/11/15), `MerchantDashboard` Google card (AC3/6/7/15) |
| Manual | Docker / Swagger | End-to-end picker on `/merchant/dashboard`, public profile section, optional real-provider smoke if a key is present |

`GOOGLE_PLACES_API_KEY` is unset in this environment, so every backend call
exercises `MockReviewSourceProvider` (AC16). No local Redis is reachable; sync
tests monkeypatch `try_acquire_lock` / `release_lock` so fail-closed lock
behavior does not masquerade as debounce.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated (frontend) | `GooglePlacePicker.test.tsx` — search box prefilled; map `center` passed through to `BusinessMapClient` after search |
| 2 | Automated (frontend) | `GooglePlacePicker.test.tsx` — list rows + pins share one `selectedPlaceId` |
| 3 | Automated | Backend: `test_link_then_status_reflects_linked_state`. Frontend: `MerchantDashboard.test.tsx` linked card; picker confirm calls `linkGooglePlace` |
| 4 | Automated | Backend: `test_search_empty_candidates_is_200`. Frontend: inline empty state + retry |
| 5 | Automated | Backend: `test_search_provider_error_returns_502_and_leaves_link_untouched`, `test_sync_provider_error_returns_502_and_leaves_rows`. Frontend: readable alert on search failure |
| 6 | Automated (frontend) | `MerchantDashboard.test.tsx` — link prompt, no Sync now when unlinked. Backend: `test_status_unlinked_by_default`, `test_sync_without_link_returns_400` |
| 7 | Automated | Backend: `test_sync_creates_external_reviews_and_updates_status`. Frontend: count + Sync now when linked |
| 8 | Automated | `test_sync_is_idempotent_no_duplicate_rows` |
| 9 | Automated | `test_concurrent_sync_is_debounced` |
| 10 | Automated | Backend: `test_public_external_reviews_lists_synced_rows`. Frontend: `ExternalReviews.test.tsx` heading, author, body, View on Google |
| 11 | Automated | Backend: `test_public_external_reviews_empty_when_never_synced`. Frontend: empty list → no placeholder |
| 12 | Automated | `test_sync_does_not_change_average_rating_or_review_count` |
| 13 | Automated | `test_search_401s_unauthenticated`, `test_search_403s_for_customer`, `test_status_403s_for_customer` |
| 14 | Automated | `test_link_and_sync_403_for_non_owning_merchant` |
| 15 | Automated (frontend) | `ExternalReviews.test.tsx` + `MerchantDashboard.test.tsx` caveat copy |
| 16 | Automated | `test_unset_api_key_selects_mock_provider`, `test_search_returns_deterministic_mock_candidates` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Search / status / link / sync | anonymous | 401 |
| Search / status / link / sync | customer | 403 |
| Search / status / link / sync | merchant, not owner | 403/404 (`_load_owned_business`) |
| Search / status / link / sync | merchant, owner | 200 (or 400 sync if unlinked) |
| Same four | admin | 200 (any business) |
| `GET /businesses/{id}/external-reviews` | none | 200 |

---

## Edge cases

- Relink after `external_platform_refs.google` is set → 409 (out of scope, contract).
- Sync while unlinked → 400.
- Mock fixture includes one `body=None` review (nullable-body path).
- Debounce: lock not acquired → `debounced: true`, no rows written.
- `Business.average_rating` / `review_count` numerically unchanged across a sync.
- Table may accumulate >5 historical rows over many real syncs; public GET is `LIMIT 5` — not an AC8 failure (Architect risk).

---

## Manual checklist (if applicable)

- [ ] M-001: Merchant dashboard — open link flow; search box prefilled; Leaflet/OSM picker (no Google Maps JS).
- [ ] M-002: Zero-candidate search shows empty state; retry works.
- [ ] M-003: After link + Sync now, public `/businesses/[slug]` shows "Also reviewed on Google" only when rows exist.
- [ ] M-004: Native star average on profile / `BusinessCard` unchanged after sync.
- [ ] M-005: Swagger `/docs` shows the four `google-reviews*` routes + public `external-reviews`.
- [ ] M-006: Real `google` provider smoke (only if `GOOGLE_PLACES_API_KEY` is set and billed). **Blocked** until the key exists.

Not executed in this Tester pass (no Docker session / no Places key); flagged for PM before launch, consistent with prior slices.

---

## Environment

- `GOOGLE_PLACES_API_KEY` unset → mock provider (AC16).
- `AI_PROVIDER=mock`.
- Backend: `pytest tests/test_google_reviews.py` (targeted; full mega-suite has a known Railway-proxy flake, not chased here).
- Frontend: `cd frontend && npm test`.
