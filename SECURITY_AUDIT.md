# Security audit — 2026-08-17

Referenced from [README.md §9 Security](README.md#9-security). This is the record of a
security review requested from a pentesting/"what does it take to approve this site" angle:
what was checked, what was found, what got fixed on branch `fix/security-hardening-p0-p1`,
what was deliberately deferred (and why), and how each fix was verified.

The review covered three areas in parallel: the FastAPI backend (`backend/app/`), the
Next.js frontend (`frontend/`), and infra/CI (`docker-compose.yml`, `Dockerfile`s,
`.github/workflows/`).

## What "secure" is being checked against

No single certificate exists; reviewers/pentesters work down a checklist like this one —
auth & authorization (token design, and critically, does every endpoint check *ownership*,
not just "is logged in"), input handling (injection, upload validation), transport & headers
(TLS, CSP, cookie flags, CORS), where credentials live client-side, secrets hygiene,
dependency hygiene, infra/network exposure, error-handling leakage, rate limiting, and
logging. The findings below are organized the same way.

## Fixed in this pass

### Critical

**1. IDOR on business photo upload.** `POST /photos/upload` only required
`Depends(get_current_user)` — any authenticated customer could upload or overwrite a photo
(including `logo`/`storefront`, which write straight to `Business.logo_url` /
`storefront_url`) on a business they don't own. `DELETE /photos/{photo_id}` already checked
ownership; the upload path didn't.
- Fix: `[backend/app/routers/photos.py](backend/app/routers/photos.py)` now checks the
  target business exists and that the caller is `ADMIN` or the owning `MERCHANT` before
  the business-gallery path runs. The review-attachment path (photo tied to a review, no
  `business_id`) is unaffected — that one was never the vulnerable path.
- Verified: new regression tests in `[backend/tests/test_photos.py](backend/tests/test_photos.py)`
  — owning merchant succeeds (201), a different merchant gets 403, a customer gets 403.
  Written in the same pattern as the existing `test_businesses_mine.py`, but **could not be
  executed in this environment** (no local Postgres/Docker available here — see
  "Not independently verified" below). Run `cd backend && pytest tests/test_photos.py -v`
  against Compose before merging.

**2. No rate limit on TOTP verify/confirm or refresh.** `/auth/mfa/totp/verify`,
`/auth/mfa/totp/confirm`, and `/auth/refresh` had no `@limiter.limit`, unlike every other
auth endpoint. An attacker holding a valid 10-minute `mfa_token` could brute-force the
6-digit TOTP code unthrottled.
- Fix: added the existing `slowapi` limiter (`5/minute` on the two TOTP endpoints, `10/minute`
  on refresh, matching login's rate) in
  `[backend/app/routers/auth.py](backend/app/routers/auth.py)`.
- Verified: `cd backend && pytest tests/test_mfa.py tests/test_auth_hardening.py -v` — 23/23
  passed. (These call the router functions directly with a fake `Request`, the same pattern
  the existing login/register tests already used — three existing direct-call tests needed
  their call sites updated to pass `fake_request()` as the new first argument, since the
  decorator requires a real `Request` to read the client IP from.)

### High

**3. No Content-Security-Policy or frontend HSTS.** `next.config.js` set the other standard
headers but no CSP, and only the backend sent HSTS.
- Fix: `[frontend/next.config.js](frontend/next.config.js)` now sends a CSP scoped to
  `'self'` + the actual `NEXT_PUBLIC_API_URL` origin + `accounts.google.com` (Google
  Sign-In script/iframe) + the OpenStreetMap tile/Nominatim hosts Leaflet needs, plus
  `Strict-Transport-Security`. `script-src`/`style-src` keep `'unsafe-inline'` (Next's own
  hydration bootstrap and Tailwind's runtime style injection need it; removing it needs a
  nonce-based policy via a new `middleware.ts`, deferred — see below). `'unsafe-eval'` is
  added to `script-src` **only in development** (`NODE_ENV !== "production"`), since Next
  dev mode evals webpack's source-mapped chunks; production builds don't get that
  relaxation.
- Verified live in the browser: started the frontend dev server, confirmed via
  `fetch(location.href).then(r => r.headers)` that the CSP header is present and correctly
  resolves the API origin (`https://backend-production-2783.up.railway.app` from this
  session's `.env`), checked the console on `/`, `/login`, and `/search` for CSP violation
  reports (none), and confirmed no regression from the initial `'unsafe-eval'` issue caught
  on the first pass (dev-mode eval violation, fixed by scoping it to dev only). The Google
  Sign-In flow itself wasn't exercised end-to-end (no `NEXT_PUBLIC_GOOGLE_CLIENT_ID`
  configured in this environment, so the button doesn't render) — worth a manual click-through
  before merging.

### Medium (infra)

**4. Postgres/Redis ports open on all interfaces in `docker-compose.yml`.** `"5432:5432"` /
`"6379:6379"` bind to every host interface, not just loopback. Dev-only in practice, but a
risky pattern to carry into anything prod-adjacent.
- Fix: changed to `"127.0.0.1:5432:5432"` / `"127.0.0.1:6379:6379"` in
  `[docker-compose.yml](docker-compose.yml)`. `backend`/`frontend` ports (8000/3000) are left
  as-is — those are meant to be reachable from the host browser.

**5. Containers ran as root.** Neither `Dockerfile` set a non-root `USER`.
- Fix: `[backend/Dockerfile](backend/Dockerfile)` creates a system user `app` and chowns
  `/app` before switching to it. `[frontend/Dockerfile](frontend/Dockerfile)` switches to the
  `node` user the official Node image already provides.
- **Not independently verified** — no Docker available in this environment to run
  `docker compose up --build`. Caveat worth knowing before merging: `docker-compose.yml` bind-mounts
  `./backend:/app` and `./frontend:/app` over the image for hot-reload dev, which on a native
  Linux Docker host can produce permission errors if the bind-mounted files' host UID doesn't
  match the container's new non-root UID. This is a known non-issue on Docker Desktop for
  Windows/Mac in the common case, but run `docker compose up --build` locally and confirm both
  services start cleanly before merging this branch.

**6. CI workflows had no explicit least-privilege `permissions:` and no dependency-audit
step.** Only `web-e2e.yml` declared `permissions: contents: read`; the rest relied on the
default token scope. Dependabot was wired up for version bumps, but nothing scanned for
known CVEs in CI.
- Fix: added `permissions: contents: read` to `backend-tests.yml`, `frontend-tests.yml`,
  `agent-config-sync.yml`, `mobile-build-apk.yml`, `mobile-release-aab.yml`, and
  `mobile-emulator-check.yml`. Added a `pip-audit` step to `backend-tests.yml` and an
  `npm audit --audit-level=high` step to `frontend-tests.yml`.
- Not run in CI yet (both workflows are `workflow_dispatch`-only per the repo's documented
  known gap — see README §14). First manual dispatch of each after merging should be checked
  for audit-step false positives before relying on it as a gate.

### Verified safe (no change needed)

- **`/uploads` static mount** (`app.mount("/uploads", StaticFiles(...))` in
  `backend/app/main.py`) does not enumerate directory contents — Starlette's `StaticFiles`
  404s on a bare directory request rather than listing it. Combined with the UUID-based
  filenames already in place, this closes both the directory-listing and path-traversal
  angles on uploads.
- **TOTP QR SVG rendering** (`dangerouslySetInnerHTML` in `frontend/src/components/LoginForm.tsx`)
  renders `qr_svg` from `POST /auth/mfa/totp/setup`, which the backend generates server-side
  via `qr_svg_for_uri()` (`backend/app/services/mfa.py`) from a server-generated secret — no
  user-controlled input reaches that SVG, so this isn't an XSS vector in practice.
- **SQL injection**: all DB access goes through SQLAlchemy's async ORM/Core `select()`; no
  raw SQL or string-built queries found anywhere in `backend/app/`.
- **Secrets in git**: `backend/.env` (holding a real Railway `DATABASE_URL`) was confirmed via
  `git log --all -- backend/.env` to have never been committed, and is correctly listed in
  `.gitignore`. Recommend rotating that credential anyway since it's a live secret sitting in
  plaintext on disk — routine hygiene, not a code fix.

## Deliberately deferred (not fixed in this pass)

These are real findings, left out of this branch on purpose — either because the fix is a
bigger architectural change than a hardening batch should carry, or because completing it
safely needs something this session couldn't do (a network lookup, a running Docker daemon,
a Google Cloud Console login).

| # | Finding | Why deferred |
| - | ------- | ------------- |
| 1 | JWT access **and** 7-day refresh tokens live in `localStorage` (`frontend/src/lib/api.ts`) — any XSS anywhere exfiltrates both | This is already tracked as README §9 "Known weaknesses" #1 / **S-026 / ADR-004**. Fixing it means httpOnly cookies + CSRF handling + touching every `localStorage` read site (`RequireAuth`, `FavoriteButton`, `ProfilePage`, `SettingsPage`, `ReviewForm`, `ClientLayout`) — an auth-architecture change that needs its own PM → Architect → Builder → Tester slice per this repo's mandatory workflow, not a hotfix branch. |
| 2 | `python-jose` (unmaintained since 2021) and `passlib` (unmaintained since 2020) in `backend/requirements.txt` | HS256 is pinned so the known `python-jose` algorithm-confusion CVEs don't directly apply, but both should eventually move to `PyJWT` / bcrypt-direct. A dependency swap on the auth path needs its own test pass, not a drive-by change in a hardening batch. |
| 3 | Third-party GitHub Actions pinned to tags (`@v4`) not commit SHAs | Hand-typing 40-char SHAs across 7 workflow files without a reliable way to verify each one in this session risks silently breaking CI with a wrong or non-existent SHA — worse than the tag-pinning it would replace. Do this with a tool (e.g. `pin-github-action`) or Dependabot's SHA-pinning support, not by hand. |
| 4 | Railway `DATABASE_URL` in `backend/.env` is a live credential sitting in plaintext on disk | Rotation is a Railway dashboard action, not a code change — flagged above as routine hygiene. |
| 5 | `NEXT_PUBLIC_GOOGLE_MAPS_KEY` / `NEXT_PUBLIC_GOOGLE_CLIENT_ID` referrer/domain restrictions | Can only be confirmed in Google Cloud Console, not from the repo. |

## Not independently verified in this session

No Docker and no local Postgres/Redis were available in this environment, which limits what
could be proven end-to-end before merging:

- `backend/tests/test_photos.py` (new) needs a real Postgres — written against the same
  fixture pattern as `backend/tests/test_businesses_mine.py` but not executed here.
- `docker compose up --build` — needed to confirm the non-root `Dockerfile` changes don't
  break the bind-mounted local dev flow (see finding #5 above).
- The full backend suite (`cd backend && pytest`) and the dispatch-only CI workflows
  (`backend-tests.yml`, `frontend-tests.yml`) — only the DB-independent subset
  (`test_mfa.py`, `test_auth_hardening.py`, 23 tests) could run here; the frontend Jest suite
  did run in full (`cd frontend && npm test` — 197/197 passed).

Run `cd backend && pytest` and `docker compose up --build` locally before merging.

## Not attempted (explicitly out of scope for this pass)

- Full external/third-party penetration test — this was a code + config review, not a live
  pentest against a running deployment.
- Anything requiring credentials this session doesn't have (Railway dashboard, Google Cloud
  Console, GitHub branch protection settings).
