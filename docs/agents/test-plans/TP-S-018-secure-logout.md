# TP-S-018: Secure logout / session UX — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-018 |
| **Author** | Tester |
| **Date** | 2026-08-11 |

> Tested together with S-019 and S-020 — all three were implemented in the same change
> and share the login/profile/session code paths (`frontend/src/lib/api.ts`,
> `RequireAuth`, `ClientLayout`, `ProfilePage`, `SettingsPage`, `AlreadySignedIn`,
> `backend/app/routers/auth.py`). See TP-S-019 and TP-S-020 for the adjacent plans.

---

## Scope

`performLogout` (token revoke + clear + hard navigate), the bfcache `pageshow`
re-check pattern shared by `RequireAuth`/`ClientLayout`/`SettingsPage`/`ProfilePage`/
`AlreadySignedIn`, and the existing `POST /auth/logout` blocklist mechanism it relies
on (no new backend endpoint in this slice).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Frontend | Jest + RTL | `performLogout` behavior, `RequireAuth` guard + pageshow re-check |
| Backend | pytest | Existing `test_auth_logout.py` / `test_dependencies_blocklist.py` (blocklist mechanics) plus one written (not live-executed — see note below) integration assertion that a revoked token fails `GET /auth/me` |
| Manual | Browser / `docker compose up --build` | Real Back-button/bfcache behavior, Navbar/Settings logout controls |

**Environment note:** `backend/.env`'s `DATABASE_URL` points at the live Railway
Postgres instance used for this environment — there is no isolated/ephemeral test DB
and no Docker available here to spin one up. Backend tests that call mutating
endpoints (`/auth/login`, `/auth/logout` via ASGI+DB, `PATCH /auth/me`, etc.) were
**not executed live** in this pass to avoid writing further rows to that database (a
prior baseline run before this constraint was identified already persisted rows —
see the S-020 test report gaps section). Backend AC coverage for anything that would
require a live mutating call is via **code review** plus the pre-existing
fully-mocked unit tests (`test_auth_logout.py`, `test_dependencies_blocklist.py`,
`test_mfa.py`), which do not touch the real database at all and were run live.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. Logout from Navbar/Settings clears tokens + hard-navigates | Automated | `frontend/src/lib/__tests__/api.test.ts::performLogout` (both cases) |
| 1. (wiring) Navbar/SettingsPage/AlreadySignedIn/ClientLayout call `performLogout` with the right redirect | Manual + code review | M-001; `frontend/src/app/ClientLayout.tsx`, `frontend/src/components/SettingsPage.tsx`, `frontend/src/components/AlreadySignedIn.tsx` |
| 2. Back button to a protected page after logout → sent to login / no authenticated shell | Automated (mechanism) + Manual (real browser) | `frontend/src/components/__tests__/RequireAuth.test.tsx::"redirects to /login and renders nothing when there is no stored access token"`; M-002 |
| 3. Revoked tokens → `auth.me()` fails → local tokens cleared | Automated | `RequireAuth.test.tsx::"clears local tokens and redirects to /login when auth.me() fails"` and `"re-verifies on a bfcache pageshow restore and clears tokens if the session is no longer valid"`; backend blocklist mechanics in `backend/tests/test_auth_logout.py`, `backend/tests/test_dependencies_blocklist.py` (already existing, executed, no DB); backend integration proof written in `backend/tests/test_s018_s020_login_profile.py::test_password_login_totp_and_profile_enrichment_flow` (logout → `GET /auth/me` → 401) — **written, not executed live** (production DB constraint) |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated `POST /auth/logout` | none | 401 (`test_auth_logout.py::test_logout_without_credentials_returns_401`, existing) |
| Refresh token used as the logout Bearer credential | any | 401 (`test_auth_logout.py::test_logout_rejects_refresh_token_used_as_access_token`, existing) |

No role-gated resource in this slice (logout is available to every authenticated
role) — the auth-baseline cases above stand in for the RBAC matrix.

---

## Edge cases

- Malformed/garbage `refresh_token` in the logout body must not fail the request —
  already covered by `test_auth_logout.py::test_logout_ignores_garbage_refresh_token`.
- `performLogout` must still clear local tokens and navigate when the server-side
  revoke call itself fails (network error) — `api.test.ts::"still clears local tokens
  and navigates when the server revoke call fails"`.
- bfcache restore (`pageshow` with `persisted: true`) on a page where the session was
  revoked *after* the page was first shown — `RequireAuth.test.tsx` pageshow test.

---

## Manual checklist (if applicable)

- [ ] M-001: `docker compose up --build`; log out from the Navbar and separately from
      `/settings`; confirm URL hard-navigates and the Navbar immediately shows
      signed-out (Login/Sign Up links, no user menu).
- [ ] M-002: Log in, navigate to a protected page (`/profile`), log out, then press the
      browser **Back** button — confirm the protected page is not shown from bfcache
      with an authenticated shell (either redirected to `/login` or the guard blocks
      rendering).

---

## Environment

- `AI_PROVIDER=mock`
- `docker compose up --build` (for the manual checklist)
- Backend live-DB execution intentionally skipped this pass — see environment note
  above.
