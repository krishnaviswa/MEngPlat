# TR-S-018: Secure logout / session UX — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-018 |
| **Author** | Tester |
| **Date** | 2026-08-11 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 3 AC verified — 2 fully by automated test, 1 partly by automated test plus
manual/code-review for the real-browser bfcache and multi-entry-point pieces that Jest
cannot exercise. No bugs found; no code changes made to this slice's implementation.

**Important environment finding (flagged, not a slice-implementation bug):**
`backend/.env`'s `DATABASE_URL` points at the live Railway Postgres instance for this
environment — there is no isolated/ephemeral test database and no Docker available
here to create one. A baseline full-suite `pytest` run I performed early in this pass
(before this was identified) already persisted real rows to that database — confirmed
by a `409` conflict on a fixed test email (`testuser@example.com`) that a pre-existing
test file (`test_api.py`) reuses without a uuid suffix. No further mutating backend
tests were executed once this was flagged. This is tracked below as a gap for the test
infrastructure generally, not specific to S-018's code.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | Logout from Navbar/Settings clears tokens and hard-navigates so Navbar shows signed-out | A + M | `frontend/src/lib/__tests__/api.test.ts::performLogout` (both cases); wiring in `ClientLayout.tsx`/`SettingsPage.tsx`/`AlreadySignedIn.tsx` verified by code review; M-001 | Pass |
| 2 | Back button to a protected page after logout → sent to login / no authenticated shell | A + M | `frontend/src/components/__tests__/RequireAuth.test.tsx::"redirects to /login and renders nothing when there is no stored access token"`; M-002 (real bfcache, not executed — no browser in this environment) | Pass (automated); M-002 not executed |
| 3 | Revoked tokens → `auth.me()` fails on a guarded page → local tokens cleared | A | `RequireAuth.test.tsx::"clears local tokens and redirects to /login when auth.me() fails"`, `"re-verifies on a bfcache pageshow restore and clears tokens if the session is no longer valid"`; backend blocklist mechanics: `backend/tests/test_auth_logout.py` (5 tests, executed, no DB), `backend/tests/test_dependencies_blocklist.py` (2 tests, executed, no DB) | Pass |

**Coverage:** 3 / 3 AC mapped

---

## Backend tests

### Added
None new for this slice specifically — S-018 reuses the pre-existing `POST
/auth/logout` route and blocklist mechanism, which already has full unit coverage in
`backend/tests/test_auth_logout.py` and `backend/tests/test_dependencies_blocklist.py`.
One shared integration test spanning all three slices was written in
`backend/tests/test_s018_s020_login_profile.py` (see TR-S-020 for detail); its
`test_password_login_totp_and_profile_enrichment_flow` includes a logout →
`GET /auth/me` → 401 assertion relevant to this slice's AC3, but per the environment
note above it was **not executed live**.

### Run output
```
cd backend && .venv/Scripts/python.exe -m pytest -v tests/test_auth_logout.py tests/test_dependencies_blocklist.py

tests/test_auth_logout.py::test_logout_blocklists_access_and_refresh_tokens PASSED
tests/test_auth_logout.py::test_logout_without_refresh_token_only_blocklists_access PASSED
tests/test_auth_logout.py::test_logout_without_credentials_returns_401 PASSED
tests/test_auth_logout.py::test_logout_ignores_garbage_refresh_token PASSED
tests/test_auth_logout.py::test_logout_rejects_refresh_token_used_as_access_token PASSED
tests/test_dependencies_blocklist.py::test_get_current_user_rejects_blocklisted_token_without_hitting_db PASSED
tests/test_dependencies_blocklist.py::test_get_current_user_proceeds_to_db_when_not_blocklisted PASSED

7 passed
```
These 7 tests call router/dependency functions directly with fakes/mocks (see file
docstrings) — no real database connection is opened, so they were safe to (re-)run
live under the production-DB constraint.

---

## Frontend tests

### Added
- `frontend/src/lib/__tests__/api.test.ts` — extended with a `describe("performLogout", ...)` block (2 tests)
- `frontend/src/components/__tests__/RequireAuth.test.tsx` — new file (5 tests)

### Run output
```
cd frontend && npx jest src/lib/__tests__/api.test.ts src/components/__tests__/RequireAuth.test.tsx

PASS src/lib/__tests__/api.test.ts (8 tests incl. 2 new performLogout tests)
PASS src/components/__tests__/RequireAuth.test.tsx (5 tests)

Test Suites: 2 passed, 2 total
Tests:       13 passed, 13 total
```
Full suite (`cd frontend && npx jest`) also run: **10 suites / 38 tests, all passed**
— no regressions from these additions.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `docker compose up --build`; log out from Navbar and from Settings; confirm hard navigation + Navbar shows signed-out | Not executed — no Docker available in this environment. Code-reviewed instead: `ClientLayout.tsx` wires `Navbar`'s `onLogout` to `performLogout("/")`; `SettingsPage.tsx` wires its Logout button to `performLogout("/")`; `AlreadySignedIn.tsx` wires its logout link to `performLogout("/login")`. All three call the same tested `performLogout` function. |
| M-002 | Real browser Back button after logout to a protected page | Not executed — no browser/Docker available in this environment. The underlying mechanism (`RequireAuth`'s no-token-redirect and pageshow re-check) is automated-tested; genuine bfcache restore behavior is browser-engine-specific and cannot be simulated in jsdom. |

---

## Regressions

None observed. Full frontend suite (38 tests) and the two safe (non-DB) backend test
files (7 tests) pass after this pass's additions.

---

## Gaps / rework items

1. **Test infra gap (not a slice bug):** no isolated/ephemeral backend test database
   exists in this environment; `backend/.env`'s `DATABASE_URL` is the live production
   Railway Postgres instance. This blocked live execution of the new cross-slice
   integration test and re-execution of pre-existing DB-backed test files
   (`test_api.py`, `test_businesses_mine.py`, `test_s011_s016_batch.py`, etc.). Those
   pre-existing files also already had `409`-conflict evidence of accumulated rows
   from prior runs (`testuser@example.com`) — a pre-existing test-hygiene issue, not
   introduced this pass. Recommend a dedicated ephemeral test DB (Dockerized Postgres
   or similar) before this suite is relied on for CI gating.
2. **AC2/M-002 not manually verified** — no browser/Docker in this environment. The
   automated `RequireAuth` guard tests cover the reachable mechanism; a human (or a
   future Playwright pass per `TP-S-010`) should confirm the real bfcache case before
   this is considered fully closed end-to-end.
3. Component-level logout wiring (Navbar/SettingsPage/AlreadySignedIn button →
   `performLogout` call) is verified by code review, not a dedicated RTL test per
   component — `performLogout` itself is fully tested; the wiring is a one-line
   `onClick`/`onLogout` call in each component. Low risk; flagged rather than added as
   3 near-duplicate tests, per the "prefer extending over duplicating" guidance.

None of the above block shipping — they're either environment limitations outside
this session's control or low-risk, explicitly-flagged residual coverage gaps.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (auth baseline: unauthenticated logout → 401, refresh-as-access → 401)
- [x] AI disclaimer verified (if applicable) — N/A, no AI-generated content in this slice
- [x] Ready for PM acceptance
