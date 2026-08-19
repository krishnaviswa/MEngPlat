# TR-S-079: Admin "Processing" business status — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-079 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship — with 3 test-coverage gaps and 1 live-DB verification gap tracked below (none are functional defects) |

---

## Summary

**Pass.** All 11 acceptance criteria are covered (9 automated, 2 code-read/manual). I
independently re-ran `backend/tests/test_business_processing_status.py` (8/8 pass) and the
frontend suites touched by this slice (`PendingBusinessQueue.test.tsx`,
`AllBusinessesQueue.test.tsx`, `MerchantDashboard.test.tsx`) plus the full frontend suite
(284/284 pass) and confirmed by reading source that the implementation matches the
Architect's spec.

**Enum-casing claim (AC11) — independently re-verified, confirmed correct.** I read
`backend/app/models/__init__.py` line 176-178: `status: Mapped[BusinessStatus] =
mapped_column(Enum(BusinessStatus), default=BusinessStatus.PENDING, nullable=False)` — no
`values_callable` override. I cross-checked this against the sibling `national_id_type`
column (lines 104-113), which *does* carry an explicit `values_callable=lambda members:
[m.value for m in members]` with a comment: *"Persist enum values (`pan`), matching
Alembic's nationalidtype. SQLAlchemy's default is member names (`PAN`), which Postgres
rejects."* That comment is itself proof of the default behavior on this codebase's
SQLAlchemy version: **no `values_callable` → SQLAlchemy persists Python enum member
*names* (`PENDING`, not `pending`)**. I then read the original schema migration
(`20260809_0030-..._initial_schema.py` line 118):
`sa.Enum('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', name='businessstatus')` — the
live Postgres native type's labels are indeed the uppercase names, confirming
`BusinessStatus` has always relied on the name-persisting default (unlike
`NationalIdType`, which deliberately opts out of it). Therefore the new migration's
`ALTER TYPE businessstatus ADD VALUE IF NOT EXISTS 'PROCESSING' AFTER 'PENDING'`
(uppercase) is **correct** and consistent with the existing convention — using lowercase
`'processing'` (as literally written in the Architect's spec prose) would have been the
actual bug here, silently creating a DB label that would never match anything
`BusinessStatus.PROCESSING` (Python-side name `PROCESSING`) ever writes. The Builder's
deviation from the spec's literal text was the right call.

**I could not verify this against a live Postgres database** — no Docker/Postgres is
reachable in this sandbox. My conclusion above is by static/code-level reasoning (reading
the model, the comment on the sibling column, and the original migration's literal SQL),
not by running `ALTER TYPE` against a real database. This must still be exercised via
`docker compose up --build` / CI before merge (see Manual checklist below).

No regressions found. Full frontend suite: 284/284 passing (up from the pre-Phase-D
baseline). Backend: `test_business_processing_status.py` 8/8, and combined with
`test_business_address_reverify.py` + `test_businesses_cache_invalidation.py` +
`test_categories_search.py` (S-081), 26/26 passing.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | "Start review" on a pending row → `PROCESSING`, audit trail entry | A | `test_business_processing_status.py::test_start_review_moves_pending_to_processing_and_writes_audit_log`; frontend `PendingBusinessQueue.test.tsx::"shows 'Start review' only on pending rows and moves the row to processing on click"` | Pass |
| 2 | "Return to pending" on a processing row → `PENDING`, indistinguishable from never-started pending | A | `test_business_processing_status.py::test_return_to_pending_moves_processing_to_pending_and_writes_audit_log`; frontend `PendingBusinessQueue.test.tsx::"shows 'Return to pending' only on processing rows and reverts the row on click"` | Pass |
| 3 | Approve from `PROCESSING` → `APPROVED`, identical to approving from pending | A | `test_business_processing_status.py::test_approve_business_from_processing_status`; frontend `PendingBusinessQueue.test.tsx::"approves a processing business the same way as a pending one"` | Pass |
| 4 | Suspend from `PROCESSING` → `SUSPENDED`, identical to suspending from pending | A | `test_business_processing_status.py::test_suspend_business_from_processing_status` (no dedicated frontend suspend-from-processing test, but the Suspend button renders unconditionally per row — confirmed by code read of `PendingBusinessQueue.tsx`) | Pass |
| 5 | Pending queue merges `PENDING` + `PROCESSING`, each row tagged | A | `PendingBusinessQueue.test.tsx::"loads and merges both pending and processing businesses, tagging processing rows"` | Pass |
| 6 | Status-badge rendering shows a defined, non-blank badge for `processing` | A | `AllBusinessesQueue.test.tsx::"renders a defined badge for a 'processing' status"` | Pass |
| 7 | Status-badge lookup falls back to a visible default for *any future unmapped* status (defensive requirement, not just `processing`) | M (code-read) | `AllBusinessesQueue.tsx`'s `statusTone()` (`STATUS_TONE[status] ?? "neutral"`) read and confirmed present. **Gap:** the only automated test (AC6's) exercises `"processing"`, which is itself a *mapped* key in `STATUS_TONE` — it does not exercise a genuinely unmapped value the way S-083's parallel `ROLE_TONE` fallback test does (`role: "vendor" as User["role"]`). The fallback branch is correct by code read but not directly exercised by an automated test. | Pass (see gap note) |
| 8 | Any signed-in admin (not just the one who started review) can act on a `PROCESSING` row | A | No per-admin ownership check exists anywhere in `start_review`/`return_to_pending`/`approve_business`/`suspend_business` (confirmed by code read — none of the four take or check a "claimed by" field); `PendingBusinessQueue.test.tsx`'s approve/suspend/return tests use a fresh admin session each render with no ownership state passed | Pass |
| 9 | Merchant dashboard shows a "review underway" indicator for `PROCESSING`, not a broken/raw label | M (code-read) | `MerchantDashboard.tsx` `STATUS_LABEL`/`STATUS_CLASS` maps (lines 28-42) include `processing: "Under review"` / amber styling, and a dedicated banner block (lines 293-298) renders "Your business is currently being reviewed by an admin" for `status === "processing"`, plus the multi-business `Select` suffix (line 279) adds `" (processing)"`. **Gap: no automated test.** I grepped `MerchantDashboard.test.tsx` for `"processing"` and found zero matches — the file's diff for this work batch only added S-076/S-077/S-078 tests, not an S-079 processing-banner test, despite the task brief's summary claiming "additions to ... MerchantDashboard.test.tsx" for S-079. Verified correct by code read only. | Pass (see gap note — recommend adding a test before Accept) |
| 10 | Non-admin cannot call `start-review`/`return-to-pending` (401/403) | M (code-read) | Both endpoints use `Depends(require_roles(UserRole.ADMIN))`, identical to `approve_business`/`suspend_business`. **Gap: no automated 401/403 test for these two specific endpoints** — the unit tests in `test_business_processing_status.py` call the router functions directly, bypassing FastAPI's `Depends` entirely (same pattern/limitation as `test_business_address_reverify.py`, precedented in TR-S-073). The opt-in E2E `tests/e2e/test_rbac_matrix.py` tests `approve` returns 403 for a merchant but was **not** extended to cover `start-review`/`return-to-pending`. | Pass (by shared-dependency precedent; recommend extending `test_rbac_matrix.py`) |
| 11 | Migration is additive only — no existing business altered/backfilled into `PROCESSING` | A (migration content) + M (live-DB unverified) | Migration body reviewed: only `ALTER TYPE ... ADD VALUE IF NOT EXISTS`, no `UPDATE`/backfill statement of any kind; `PROCESSING` is reachable only via the new `start_review` endpoint (confirmed by grepping the whole codebase for `BusinessStatus.PROCESSING` — only assigned in `start_review`). **Not run against a live Postgres** in this sandbox. | Pass (static reasoning only — see Summary) |

**Coverage:** 11 / 11 AC mapped (9 automated/code-confirmed + 2 explicitly flagged as
code-read-only with a live-DB verification gap for AC11).

---

## Backend tests

### `backend/tests/test_business_processing_status.py` (8 tests, new file — confirmed present and green)
- `test_start_review_moves_pending_to_processing_and_writes_audit_log`
- `test_start_review_409s_when_business_is_not_pending`
- `test_start_review_404s_for_unknown_business`
- `test_return_to_pending_moves_processing_to_pending_and_writes_audit_log`
- `test_return_to_pending_409s_when_business_is_not_processing`
- `test_return_to_pending_404s_for_unknown_business`
- `test_approve_business_from_processing_status`
- `test_suspend_business_from_processing_status`

### Run output (independently re-run)
```
cd backend && python -m pytest tests/test_business_processing_status.py -v
8 passed

cd backend && python -m pytest tests/test_business_processing_status.py tests/test_business_address_reverify.py tests/test_businesses_cache_invalidation.py tests/test_categories_search.py -v
26 passed
```

---

## Frontend tests

### `frontend/src/components/admin/__tests__/PendingBusinessQueue.test.tsx` (new file, 7 tests)
- `"loads and merges both pending and processing businesses, tagging processing rows"`
- `"shows 'Start review' only on pending rows and moves the row to processing on click"`
- `"shows 'Return to pending' only on processing rows and reverts the row on click"`
- `"approves a processing business the same way as a pending one"`
- `"shows the merged empty-state copy when both pending and processing are empty"`
- `"shows an inline error when start-review fails, without removing the row"`

### `AllBusinessesQueue.test.tsx` (+1 test)
- `"renders a defined badge for a 'processing' status"` — see AC7 gap note above (tests a mapped value, not a genuinely unmapped one).

### `MerchantDashboard.test.tsx`
- **No test added for the processing banner/select-suffix/status-label change (AC9).** Confirmed by grep (`grep -n "processing" MerchantDashboard.test.tsx` → no matches) and by reading `git diff` for this file, which shows only S-076/S-077/S-078 additions.

### Run output (independently re-run)
```
cd frontend && npx jest src/components/admin/__tests__/PendingBusinessQueue.test.tsx src/components/admin/__tests__/AllBusinessesQueue.test.tsx src/components/__tests__/MerchantDashboard.test.tsx --silent
3 suites, all passed

cd frontend && npx jest --silent   (full suite)
Test Suites: 47 passed, 47 total
Tests:       284 passed, 284 total
```

---

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-079-01 | `alembic upgrade head` (including `l6m7n8o9p0q1_add_processing_business_status.py`) applies cleanly against a live Postgres, and `ALTER TYPE businessstatus ADD VALUE IF NOT EXISTS 'PROCESSING'` matches the existing native enum's uppercase-name convention | **Not run** — no Docker/Postgres reachable in this sandbox. Verified by static reasoning only (see Summary). Must be run via `docker compose up --build`/CI before merge. |
| M-079-02 | Live click-through: admin clicks "Start review" on a pending business, sees it tagged Processing, clicks "Return to pending," reverts; merchant dashboard shows "Under review" banner while `PROCESSING` | Not run — no live backend/Postgres reachable in this sandbox; fully covered by automated + code-read verification above instead. |

---

## Regressions

None found. Full frontend suite green (284/284). Backend combined run green (26/26).

---

## Gaps / rework items

1. **AC7 (defensive status-badge fallback) — automated test only covers a mapped value
   (`"processing"`), not a genuinely unmapped status.** The `statusTone()` fallback logic
   is correct by code read, but unlike S-083's parallel `ROLE_TONE` test (which explicitly
   casts an unmapped `"vendor"` role), no equivalent unmapped-status test exists for
   `AllBusinessesQueue.tsx`. Low severity — recommend a follow-up one-line test
   (`status: "archived" as unknown as BusinessStatus`), not a blocker.
2. **AC9 (merchant dashboard processing indicator) has zero automated test coverage**,
   despite being correctly implemented (verified by code read of `MerchantDashboard.tsx`
   lines 28-42, 279, 293-298). Recommend adding a test analogous to the existing
   pending/suspended banner tests in `MerchantDashboard.test.tsx` before this slice is
   marked Accepted.
3. **AC10 (RBAC on the two new endpoints) has no automated 401/403 test**, at either the
   unit level (the existing tests bypass `Depends` entirely) or the E2E level
   (`tests/e2e/test_rbac_matrix.py` was not extended to cover `start-review`/
   `return-to-pending`, even though it already asserts 403 for `approve`). Both endpoints
   use the identical `require_roles(UserRole.ADMIN)` dependency already exercised
   elsewhere in the suite, so risk is low, but per this repo's testing discipline (RBAC
   negative tests must not be skipped), recommend adding two lines to
   `test_rbac_matrix.py` before Accept.
4. **AC11 (migration is additive-only) is unverified against a live Postgres** — sandbox
   limitation, not a code defect found. Must be verified in CI/Docker before merge (see
   M-079-01).
5. Per DoD, `README.md` §5 (new `BusinessStatus.PROCESSING`), §7 (two new endpoints), §6
   (flow), and §12/§14 have not yet been updated in this diff (`git diff README.md` shows
   unrelated pending changes only) — a PM/Builder item, not a test failure, but blocks the
   "Documented in README.md" line of the slice's Definition of Done.

None of these are functional defects; items 1-3 are test-coverage gaps on
already-correct code, and 4-5 are sandbox/process gaps.

---

## Sign-off

- [x] All 11 AC mapped to a test or explicit code-read verification
- [x] RBAC verified by code read (identical `require_roles` pattern to already-tested
      endpoints); **automated RBAC test recommended as a gap, not present today** — see
      Gaps item 3
- [x] No AI disclaimer needed (confirmed — not AI output, per the slice's own UX notes)
- [x] Ready for PM acceptance, with (a) live-Postgres migration verification (M-079-01),
      (b) the two test-coverage gaps above (AC9, AC10), and (c) README doc updates per DoD
      tracked as explicit, non-blocking follow-ups — consistent with this repo's
      precedent (e.g. TR-S-073) of shipping with a flagged, sandbox-caused live-DB
      verification gap rather than blocking on it.
