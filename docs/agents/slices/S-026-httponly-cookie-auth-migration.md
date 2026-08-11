# Slice: S-026 — httpOnly cookie auth migration (web) with dual Bearer/cookie backend support

| Field | Value |
|-------|-------|
| **Slice ID** | S-026 |
| **Phase** | 1 Foundation |
| **Status** | Specified |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-11 |

---

## User story

**As a** MerchantHub AI user signing in through the web app (customer, merchant, or admin)
**I want** my session tokens stored somewhere client-side JavaScript cannot read them (httpOnly cookies) instead of `localStorage`
**So that** a website XSS bug cannot exfiltrate my access/refresh tokens and hijack my account — while the Flutter mobile app keeps authenticating exactly as it does today via Bearer tokens in `flutter_secure_storage`

---

## Context (why now)

Today, per `frontend/src/lib/api.ts` (`getToken`, `getRefreshToken`, `storeTokens`, `clearTokens`), the web frontend stores both `access_token` and `refresh_token` in `localStorage` and attaches them via a manual `Authorization: Bearer` header on every `apiFetch` call. This is called out as an unmitigated weakness in `README.md` §9 ("Known weaknesses" row 1 / "Production hardening checklist"): any XSS on the site can read `localStorage` and steal both tokens outright.

The backend (`backend/app/dependencies.py`) authenticates purely via `HTTPBearer(auto_error=False)` reading `credentials.credentials` from the `Authorization` header — there is no cookie handling anywhere in `backend/app/routers/auth.py` or `dependencies.py` today.

The Flutter mobile client (`mobile/lib/core/storage/token_storage.dart`, `mobile/lib/core/network/auth_interceptor.dart`) reads/writes the same `access_token`/`refresh_token` pair via `flutter_secure_storage` and attaches them as a Bearer header on every request. A native mobile app has no meaningful way to participate in browser httpOnly cookies, so this cannot be a full cutover — it must be a **dual-auth** story: web moves to httpOnly cookies, backend keeps accepting Bearer tokens for mobile, simultaneously, on the same endpoints.

---

## Acceptance criteria

1. **Given** a customer, merchant, or admin logs in successfully on the web app (password + TOTP, or Google), **when** the backend issues session tokens, **then** `access_token` and `refresh_token` are set via `Set-Cookie` response header(s) with `HttpOnly`, `Secure`, and a `SameSite` attribute, are **not** present in the JSON response body delivered to the browser, and are **not** written to `localStorage`/`sessionStorage` by the frontend.
2. **Given** the same login/refresh/Google/TOTP-verify endpoints are called by the Flutter mobile app (as today, no browser cookie jar), **when** authentication succeeds, **then** the response continues to return `access_token` and `refresh_token` as JSON fields exactly as it does today, and the mobile app continues to store and send them via `flutter_secure_storage` / Bearer header, completely unaffected by this change.
3. **Given** a web session holds a valid httpOnly auth cookie and the request sends **no** `Authorization` header, **when** the browser calls a protected endpoint (e.g. `GET /api/v1/auth/me`), **then** the backend authenticates the request from the cookie and returns 200 with the user's profile.
4. **Given** a mobile (or any non-browser) client sends a valid `Authorization: Bearer <token>` header and no auth cookie, **when** it calls the same protected endpoints, **then** the backend authenticates via the Bearer token exactly as it does today — no regression — and the existing RBAC matrix (README §9) holds identically for customer, merchant, and admin routes.
5. **Given** a single request somehow carries both a valid Bearer header and a valid auth cookie, **when** the backend authenticates it, **then** the outcome is deterministic and documented (precedence rule defined by Architect), so Tester can write one repeatable test for this case rather than relying on undefined behavior.
6. **Given** a web user's access-token cookie has expired but the refresh-token cookie is still valid, **when** a request 401s, **then** the existing silent-refresh-and-retry flow in `frontend/src/lib/api.ts`'s `apiFetch` continues to work using cookies (instead of reading `refresh_token` from `localStorage`), with no visible interruption to the user — same UX class as today, cookie-backed instead of storage-backed.
7. **Given** a web user's refresh cookie is also expired, missing, or invalid, **when** a request 401s and the silent refresh fails, **then** the user is redirected to `/login` exactly as today's expired-session UX does (see S-018) — no infinite retry loop, no broken/blank state.
8. **Given** a customer, merchant, or admin logs out on the web app, **when** logout completes, **then** the backend clears/expires the httpOnly auth cookies (in addition to the existing server-side token blocklist behavior from S-001/S-018), and no valid session material remains readable by client-side JS or replayable from the browser after this call.
9. **Given** a state-changing web request (`POST`/`PATCH`/`DELETE`) is authenticated via the httpOnly cookie, **when** it is submitted, **then** the backend rejects it unless it also carries a valid anti-CSRF token/header — cookie-based auth alone must not be sufficient for writes, since browsers auto-attach cookies to cross-site requests. Bearer-token (mobile) requests, which carry no ambient browser credential, are exempt from this check.
10. **Given** `frontend/src/components/RequireAuth.tsx`'s current guard reads `localStorage.getItem("access_token")` and redirects to `/login` *before* ever calling `auth.me()`, **when** this slice ships, **then** that pre-check is removed or replaced so a validly cookie-authenticated user is not incorrectly bounced to `/login` before the server gets a chance to authenticate the cookie.
11. **Given** a returning browser still holds a pre-migration session in `localStorage` (from before this slice shipped), **when** the migrated app loads, **then** the user is treated as signed out and prompted to log in again — no crash, no infinite redirect loop, and no stale `Authorization` header sent that the backend no longer expects from a web client.
12. **Given** any of the three roles is authenticated via the new cookie mechanism, **when** they access role-gated pages/endpoints (e.g. merchant dashboard, admin moderation, business/review write actions), **then** the existing RBAC matrix in README §9 continues to hold exactly as today — this slice changes *how* identity is proven, not *what* each role is allowed to do.

---

## UX notes

- **Screens / routes:** No new screens or routes. Affects every page behind `RequireAuth` (`/profile`, `/merchant/dashboard`, `/merchant/businesses/*`, `/admin`) plus `/login`, `/register`, and the Navbar's signed-in/out state — all of these currently branch on `localStorage` token presence.
- **Components to reuse:** `RequireAuth.tsx` (guard logic updated per AC 10 — reuse the component, don't fork it); `frontend/src/lib/api.ts` (`apiFetch`, `storeTokens`/`clearTokens`, `performLogout`, `refreshTokens` — the storage *mechanism* changes, the `apiFetch`-returns-JSON-or-throws *contract* callers rely on should not); Navbar / `ClientLayout` signed-in state.
- **Empty states / errors:** Reuse the existing "session expired → redirected to `/login`" state from S-018 (AC 7). New edge case to flag for QA: if a user's browser blocks first-/third-party cookies (private browsing, strict tracking-protection extensions), the login API call may return 200 while the browser silently discards the `Set-Cookie` header, leaving the user effectively logged out on the very next request — this must surface as a visible, actionable error state, not a silent hang or blank screen.
- **AI disclaimer required?** No — this slice touches no AI-facing UI or output.

---

## Out of scope

- **Any change to the Flutter mobile app** (`mobile/lib/features/auth/`, `mobile/lib/core/storage/token_storage.dart`, `mobile/lib/core/network/auth_interceptor.dart`) — mobile keeps reading/writing Bearer tokens via `flutter_secure_storage`, unaffected by this slice (AC 2, AC 4).
- **Choice of CSRF defense mechanism** (double-submit cookie, synchronizer token, custom header check, etc.) — Architect decides the mechanism; this slice only requires that *some* CSRF protection exists for cookie-authenticated writes (AC 9).
- **`SameSite` attribute value** (`Strict` vs `Lax`), cookie `domain`/`path` scoping, and cookie naming — Architect/implementation decision, not specified by this brief.
- **The MFA challenge token (`mfa_token`) flow** (`/auth/mfa/totp/setup|confirm|verify`'s short-lived enrollment/verify token passed between login and TOTP-code submission) — unaffected by this slice; only the *final* session-token issuance points (login without MFA gate reached, `totp_confirm`, `totp_verify`, `google`, `refresh`) are in scope for cookie-setting.
- **Other README §9 "Known weaknesses" rows** — rate limiting on auth endpoints (#3), upload MIME/size validation (#5), unauthenticated `/uploads` static serving (#6) — separate slices, not bundled here.
- **Any change to the Google OAuth client-side sign-in widget/redirect UX** — only the backend token-issuance step after Google verification changes storage mechanism (AC 1); the sign-in button/flow itself is untouched.
- **Server-side session store / opaque session IDs replacing JWTs-in-cookies** — default assumption is the cookie carries the same JWT, just relocated from `localStorage`; a full session-store redesign is out of scope unless the Architect determines the JWT-in-cookie approach is unworkable.
- **Changing access/refresh token TTLs** (30 minutes / 7 days, per README §9 "Token design") — unchanged by this slice.
- **Automatic migration of a user's pre-existing `localStorage` session into a cookie** — explicitly out of scope; handled instead as a forced re-login (AC 11).
- **HTTPS/TLS termination infrastructure work** — `Secure` cookies require HTTPS, which README §10's deployed environment already assumes; provisioning/verifying HTTPS itself is not part of this slice.
- **Any visual/UI redesign** of the login, register, or logout screens.

---

## Dependencies

- **S-018 — Secure logout / session UX** (Accepted). This slice extends the same logout/token-clearing code path (`performLogout`, `POST /auth/logout`) to also clear cookies; must not regress S-018's 3 AC.
- **S-020 — Mandatory TOTP for password login** (Accepted). `totp_confirm`/`totp_verify` are among the token-issuance points that must start setting cookies for web callers (AC 1); the MFA challenge-token flow itself is unaffected (see Out of scope).
- No hard blocking dependency otherwise — this can be built directly on the current `backend/app/dependencies.py`, `backend/app/routers/auth.py`, and `frontend/src/lib/api.ts` as they exist today.

---

## Definition of done (PM)

- [ ] All 12 AC verified in test report, covering **both** the web-cookie path and the mobile-Bearer path as regression cases (not just the new cookie path in isolation)
- [ ] UX matches notes above — `RequireAuth` guard updated (AC 10), no broken redirect loops, existing S-018 session-expiry UX preserved (AC 6, AC 7)
- [ ] `README.md` §9 Security updated: "Known weaknesses" row 1 (httpOnly cookies) marked fixed, "Production hardening checklist" httpOnly-cookies line checked, the auth sequence diagram ("Store tokens (localStorage today)") and the "Browser `fetch` with `Authorization: Bearer …` from `localStorage`" framing updated to describe the dual web-cookie / mobile-Bearer mechanism; §7 API reference updated if `/auth/login`, `/auth/refresh`, `/auth/logout` request/response shapes differ for web vs. mobile callers
- [ ] `frontend/CLAUDE.md` "Auth" section (currently "Tokens in localStorage (MVP)") updated to describe the cookie mechanism, mirrored into `.cursor/rules/frontend-nextjs.mdc` in the same commit per the root `CLAUDE.md` Cursor ↔ Claude Code parity rule
- [ ] Mobile app (`mobile/`) verified unchanged — no source diff expected there beyond tests confirming no regression
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

Full rationale, alternatives considered, and the precedence/CSRF/cookie-attribute decisions
this brief deferred are captured in **ADR-004** (`docs/agents/adrs/ADR-004-httponly-cookie-dual-auth.md`).
This section is the buildable contract; read the ADR for *why*.

### Core design decisions (summary — see ADR-004 for rationale)

1. **Bearer/cookie precedence (AC 5):** the `Authorization` header, if **structurally present**
   (regardless of whether it later decodes successfully), always wins. The cookie is consulted
   **only** when no `Authorization` header is sent at all. One shared signal
   (`"authorization" in request.headers`) drives both the auth-precedence decision in
   `get_current_user`/`get_optional_user`/`logout` and the CSRF exemption below — no split-brain
   between the two checks.
2. **Web/mobile response-shape signal:** the web frontend sends a new request header
   `X-Client: web` on every `apiFetch` call. The four token-issuing endpoints
   (`totp_confirm`, `totp_verify`, `google`, `refresh`) branch on it: present → set the three
   cookies via `Set-Cookie` and omit `access_token`/`refresh_token` from the JSON body; absent
   (mobile, curl, Swagger, anything else) → unchanged JSON-body behavior, no cookies. This is
   the mechanism that makes AC 1 and AC 2 both true on the *same* endpoints.
3. **CSRF mechanism (AC 9):** stateless double-submit cookie. A new non-`HttpOnly` `csrf_token`
   cookie is set alongside the two session cookies at every issuance point. State-changing
   requests (`POST`/`PUT`/`PATCH`/`DELETE`) that are cookie-authenticated (no `Authorization`
   header, and an `access_token` or `refresh_token` cookie present) must carry an
   `X-CSRF-Token` header equal to the `csrf_token` cookie value, or the request is rejected
   with `403` before it reaches the router. Implemented as ASGI middleware
   (`app/core/csrf.py`), not a per-route dependency, so all ~10 routers are covered without
   touching every route signature. Bearer-authenticated requests skip the check entirely
   (AC 9's explicit mobile exemption), using the same signal as decision 1.
4. **Cookie attributes:** `HttpOnly` (except `csrf_token`), `Secure=True` (always — see
   ADR-004 for why this doesn't break local `http://localhost` dev), `SameSite=None`
   (frontend and backend are cross-origin in every deployment topology in README §10, so
   `Lax`/`Strict` would silently never be sent), `Path=/api/v1` (all three cookies, matching
   the API mount prefix — no `Domain` attribute, host-only, since frontend/backend don't
   share a registrable parent domain here). `Max-Age` mirrors each token's TTL
   (`access_token_expire_minutes`, `refresh_token_expire_days`); `csrf_token` mirrors the
   refresh cookie's lifetime and rotates on every reissuance.

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| POST | `/auth/register` | None | Unchanged | Unchanged (`201`, `UserResponse`) — no tokens issued here today |
| POST | `/auth/login` | None | Unchanged | **Unchanged** — password login is always TOTP-gated (S-020/ADR-001); never issues session tokens directly, so nothing to cookie-ify here. Returns `LoginResult` (`mfa_required`/`mfa_enrollment_required` + `mfa_token`) exactly as today |
| POST | `/auth/mfa/totp/setup` | `mfa_token` (body) | Unchanged | Unchanged (`TotpSetupResponse`) |
| POST | `/auth/mfa/totp/confirm` | `mfa_token` (body) | Unchanged request body | **Dual shape.** `X-Client: web` present → `Set-Cookie: access_token, refresh_token, csrf_token` (`HttpOnly`/`Secure`/`SameSite=None` on the two token cookies, `csrf_token` non-`HttpOnly`); JSON body `{"token_type":"bearer"}` — `access_token`/`refresh_token` **omitted** (`response_model_exclude_none=True`). Header absent (mobile) → unchanged JSON body `{access_token, refresh_token, token_type}`, no `Set-Cookie` |
| POST | `/auth/mfa/totp/verify` | `mfa_token` (body) | Unchanged request body | Same dual shape as `totp/confirm` |
| POST | `/auth/google` | None | Unchanged request body (`credential`) | Same dual shape as `totp/confirm` |
| POST | `/auth/refresh` | `refresh_token` query param **or** `refresh_token` cookie | **Contract widened, not broken:** `refresh_token` query param becomes `str \| None = None` (was required `str`). Mobile: keeps passing it as a query param exactly as today — byte-identical. Web: omits the query param entirely; backend falls back to `request.cookies.get("refresh_token")`. `401` if neither is present/valid. Web calls also send `X-Client: web` + `X-CSRF-Token` (this is a `POST`, cookie-authenticated once a refresh cookie exists → CSRF-gated per decision 3) | Same dual shape as `totp/confirm`; web response rotates all three cookies |
| GET | `/auth/me` | Bearer **or** `access_token` cookie (Bearer wins if both present) | None | Unchanged (`UserResponse`) |
| PATCH | `/auth/me` | Bearer or cookie; CSRF header required for cookie callers | Unchanged body | Unchanged (`UserResponse`) — now CSRF-gated when cookie-authenticated |
| POST | `/auth/logout` | Bearer **or** cookie (same precedence fallback added to `logout()`, which today hard-requires Bearer via `Depends(security)`) | Unchanged optional `{"refresh_token": "..."}` body | Unchanged `MessageResponse`. **New:** unconditionally clears all three cookies (`Set-Cookie` with `Max-Age=0`, same name/path/attrs used to set them) in addition to the existing Redis blocklist behavior (S-001/S-018) — harmless no-op for a mobile caller that never had them |
| All other protected routes (`businesses`, `reviews`, `photos`, `favorites`, `notifications`, `dashboard`, `ai`, `analytics`, `maps`) | Unchanged paths | Bearer or `access_token` cookie via the shared `get_current_user`/`require_roles` dependency chain (Bearer wins); mutating verbs (`POST`/`PATCH`/`DELETE`) CSRF-gated when cookie-authenticated, exempt when Bearer-authenticated | Unchanged | Unchanged — this is the "no regression" surface AC 4/AC 12 point at; zero router code touched beyond the shared dependency and the new middleware |

**Schema change:** `TokenResponse.access_token`/`refresh_token` become `str | None = None`
(currently required `str`). This is purely a serialization mechanism to allow *omission* for
web callers via `response_model_exclude_none=True` — mobile, which never sends `X-Client:
web`, always receives both fields populated as non-null strings, byte-identical to today.
Builder should grep `TokenResponse(` / `response_model=TokenResponse` to confirm no other
call site assumes non-null fields.

### RBAC matrix

This slice changes **how** identity is proven, not **what** each role may do — README §9's
existing role/ownership matrix is unmodified. The only new axis is *transport*:

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Authenticate via web `access_token` cookie (no `Authorization` header) | ✅ | ✅ | ✅ |
| Authenticate via mobile `Authorization: Bearer` (no cookie, or cookie ignored per precedence) | ✅ | ✅ | ✅ |
| Write action (`POST`/`PATCH`/`DELETE`) while cookie-authenticated | ✅ (CSRF header required) | ✅ (CSRF header required) | ✅ (CSRF header required) |
| Write action while Bearer-authenticated | ✅ (CSRF exempt) | ✅ (CSRF exempt) | ✅ (CSRF exempt) |
| Role/ownership checks (`require_roles`, `get_owned_business`) downstream of either transport | Identical to README §9 baseline — unaffected by this slice | Identical | Identical |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No new tables/columns, no Alembic migration. JWT claims (`sub`, `exp`, `type`,
`jti`, optional `role`/`purpose`) are unchanged — the *relocation* is transport-only (cookie
vs. JSON body for web), not a token-format or claims change. Token TTLs unchanged (out of
scope per brief).

### Cache / side effects

- No new Redis keys. `blocklist_token()`/`is_token_blocklisted()` (Redis, `app/services/cache.py`)
  are reused unchanged at logout for both the access and refresh `jti` — S-001/S-018 behavior
  is untouched, cookies are cleared *in addition to*, not instead of, that blocklist write.
- `csrf_token` is a stateless random value (`secrets.token_urlsafe(32)`), compared by direct
  string equality against the request header — **no Redis lookup, no new cache dependency**.
- No `search:*` cache interaction — auth endpoints don't touch business/review search results.

### Frontend

- **Route:** No new route. Touches every page behind `RequireAuth` plus `/login`, `/register`,
  and the signed-in-state check in `ClientLayout`/`AlreadySignedIn`.
- **Rendering:** Unchanged SSR/CSR split. `RequireAuth`/`ClientLayout`/`AlreadySignedIn` stay
  Client Components performing a client-side `auth.me()` check; the cookie rides along
  automatically via `credentials: "include"`. **Deliberately out of scope for this slice:**
  forwarding the incoming request's cookie into Server Component SSR fetches (`next/headers`
  `cookies()`) — SSR (`API_URL_INTERNAL` calls for home/search/business-profile) is already
  anonymous today (`getToken()` returns `null` server-side pre-migration too), so this slice
  doesn't change SSR's auth posture at all. Keeps the diff to the client-auth surface only.
- **Components (reuse, don't fork):**
  - `frontend/src/lib/api.ts` — `apiFetch` drops the `getToken()`/`Authorization` header
    logic entirely for the web app (cookie-only from here on) and adds: `credentials:
    "include"` on every `fetch()` (including the standalone one in `refreshTokens()`); an
    `X-Client: web` header on every request; an `X-CSRF-Token` header (read from
    `document.cookie` via a small new `getCsrfCookie()` helper) on mutating requests when a
    `csrf_token` cookie is present. `storeTokens()` becomes a no-op (the browser stores the
    `Set-Cookie` from the same response automatically — call sites in `LoginForm`/TOTP
    screens/`google` flow need no changes). `clearTokens()` is repurposed to remove the two
    **legacy** `localStorage` keys (defensive cleanup for AC 11's pre-migration-session case;
    the backend cookie-clear on `/auth/logout` is what actually ends the session).
    `apiFetch`'s 401-retry `canRetry` gate drops its `getRefreshToken()` (`localStorage`)
    truthiness pre-check — that cookie's presence isn't observable to JS anymore — and always
    attempts one silent-refresh `POST` on a retryable path's `401`, letting the backend's
    response decide success/failure (`_retried` flag still caps it to one attempt, so AC 7's
    "no infinite retry loop" still holds).
  - `frontend/src/components/RequireAuth.tsx` (AC 10, named in the brief) — remove the
    `const token = localStorage.getItem("access_token"); if (!token) { redirect }` pre-check;
    call `auth.me()` unconditionally and let the existing `.catch()` branch redirect to
    `/login`.
  - **Architect-identified addition beyond the brief's named files:**
    `frontend/src/app/ClientLayout.tsx` and `frontend/src/components/AlreadySignedIn.tsx`
    both contain the **identical** `localStorage.getItem("access_token")` pre-check-then-skip
    pattern as `RequireAuth.tsx` (same bug class as AC 10, just not named in the brief's AC
    text). Left unfixed, the Navbar would always render signed-out and the "already signed
    in" login-page gate would never fire for a validly cookie-authenticated user. Both need
    the same fix: drop the pre-check, call `auth.me()` unconditionally, keep the existing
    `.catch()` → `clearTokens()` fallback. Builder: treat this as in-scope for AC 10/12, not a
    follow-up.
- **Legacy-session handling (AC 11):** no explicit migration code needed. Once `apiFetch` stops
  reading `getToken()`/`localStorage` for the `Authorization` header, a stale pre-migration
  `localStorage.access_token` is simply never read or sent again; `auth.me()` will 401 (no
  valid cookie exists for that returning browser) and the guard components' existing `.catch()`
  path redirects to `/login` — "forced re-login," exactly as the brief specifies, falls out of
  the storage-mechanism change with no special-cased detection logic.

### Flow

Covers AC 1/3/5/6/7 end to end: web login sets cookies, a request carrying **both** a stale
Bearer header and a valid cookie resolves deterministically (AC 5), and an expired access
cookie triggers one silent refresh before falling back to the login redirect.

```mermaid
sequenceDiagram
    participant Browser
    participant Frontend as apiFetch (frontend/src/lib/api.ts)
    participant CSRF as CSRF middleware
    participant API as /auth/* (FastAPI)
    participant Dep as get_current_user
    participant DB

    Browser->>Frontend: user submits TOTP code
    Frontend->>API: POST /auth/mfa/totp/verify\nX-Client: web\nbody: {mfa_token, code}
    API->>API: verify code, issue access/refresh JWTs + csrf_token
    API-->>Browser: 200 Set-Cookie: access_token, refresh_token, csrf_token\n(HttpOnly, Secure, SameSite=None)\nbody: {token_type:"bearer"} (tokens omitted)
    Note over Browser: storeTokens() is a no-op — cookie jar already holds the session

    Browser->>Frontend: GET /api/v1/auth/me\n(cookie jar attaches access_token automatically)
    Frontend->>CSRF: GET — not a mutating verb, CSRF check skipped
    CSRF->>API: forward
    API->>Dep: get_current_user(request, credentials=None)
    Note over Dep: no Authorization header → fall back to cookie
    Dep->>Dep: decode_token(cookies["access_token"])
    Dep->>DB: SELECT user WHERE id = sub
    DB-->>Dep: user row
    Dep-->>Browser: 200 UserResponse

    Note over Browser,API: --- AC 5: precedence when BOTH are present ---
    Browser->>API: PATCH /auth/me\nAuthorization: Bearer <stale-or-valid token>\nCookie: access_token=...; csrf_token=...\nX-CSRF-Token: <matches cookie>
    API->>CSRF: Authorization header present → CSRF check SKIPPED (Bearer path exempt, AC 9)
    CSRF->>Dep: get_current_user(request, credentials=<Bearer>)
    Note over Dep: Authorization header present → cookie NEVER consulted, Bearer wins
    Dep-->>API: authenticate via Bearer only (mobile-identical code path)

    Note over Browser,API: --- AC 6/7: access cookie expired, refresh cookie still valid ---
    Browser->>API: GET /api/v1/favorites (access_token cookie expired)
    API-->>Browser: 401
    Frontend->>API: POST /auth/refresh\nX-Client: web, X-CSRF-Token\n(no query param — refresh_token cookie only)
    alt refresh cookie valid
        API-->>Browser: 200 Set-Cookie: rotated access_token/refresh_token/csrf_token
        Frontend->>API: retry GET /api/v1/favorites (once, _retried=true)
        API-->>Browser: 200
    else refresh cookie expired/missing/invalid
        API-->>Browser: 401
        Frontend->>Browser: redirect to /login (S-018 UX, no infinite loop)
    end
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 API reference style
- [x] RBAC matrix for all roles
- [x] Data model impact documented; ERD update noted if needed (none needed — no schema change)
- [x] Cache invalidation considered
- [x] AI/storage/maps use existing abstraction layers (n/a — this slice touches auth transport
      only, no AI/storage/maps code path)
- [x] No secrets in design (`csrf_token` is a random non-secret comparison value by design —
      double-submit relies on cross-origin cookie-read isolation, not the value being
      unguessable; `SECRET_KEY`-signed JWTs remain the only actual secret-bearing artifact,
      unchanged)

### Risks / tradeoffs

1. **`SameSite=None` cross-site cookies are subject to browser third-party-cookie blocking**
   (Safari ITP, Firefox ETP strict, Chrome's phased third-party-cookie deprecation) — this is
   the *exact* scenario the brief's UX notes already flag: `Set-Cookie` can be silently
   discarded while the login call itself returns `200`. Mitigation for this slice is the UX
   notes' visible/actionable error state (frontend detects "logged in but next `auth.me()`
   still 401s" and surfaces it, rather than a silent hang). The structural fix — making
   frontend and backend same-site (a proxy or shared parent domain) — is a deployment-topology
   change, out of scope here; flagged as a follow-up in ADR-004.
2. **Stateless double-submit CSRF is weaker than a session-bound/HMAC-signed variant** (see
   ADR-004 Alternatives). Accepted because there is no server-side session store for the JWTs
   themselves (out of scope to add one), and because the strict CORS origin allowlist +
   `SameSite=None` already require an attacker to both know a valid origin *and* read a
   cross-origin cookie, which a pure CSRF (no XSS) attacker cannot do.
3. **Photo upload (`POST /photos/upload`, multipart `FormData`) is a mutating, cookie-eligible
   route** — it goes through the same `apiFetch`, so it automatically gets `X-CSRF-Token`, but
   Tester should explicitly verify the CSRF middleware doesn't interfere with multipart bodies
   (it only reads headers/cookies, never `await request.body()`, so it shouldn't — but this is
   the one non-JSON write path worth a dedicated test).
4. **Existing frontend tests assume `localStorage`** (`RequireAuth.test.tsx`, `api.test.ts`,
   `LoginForm.test.tsx`, `ProfilePage.test.tsx` per the `localStorage`/`access_token` grep)
   and **will need a full rewrite** around cookie-based auth — this is Tester's job per the
   workflow, flagged here so it isn't a surprise at test-plan time.
5. **Backend auth tests** using `TestClient`/`AsyncClient` with `Authorization: Bearer` headers
   remain valid as-is (mobile-path regression coverage); new cookie-path coverage needs
   `client.cookies.set(...)`, not header manipulation.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-026-httponly-cookie-auth-migration.md`
- Test report: `docs/agents/test-reports/TR-S-026-httponly-cookie-auth-migration.md`
- ADR: [`docs/agents/adrs/ADR-004-httponly-cookie-dual-auth.md`](../adrs/ADR-004-httponly-cookie-dual-auth.md) — written; covers the Bearer/cookie precedence rule, CSRF mechanism choice, and cookie attribute decisions with alternatives considered

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-11 | PM | Slice created as a proposal/spec exercise for the httpOnly-cookie migration flagged in `README.md` §9 "Known weaknesses" row 1. Grounded in reading `frontend/src/lib/api.ts` (confirms `localStorage`-based token storage today), `backend/app/dependencies.py` / `backend/app/routers/auth.py` (confirms Bearer-only auth today, no cookie handling), and `mobile/lib/core/storage/token_storage.dart` / `mobile/lib/core/network/auth_interceptor.dart` (confirms mobile is Bearer + `flutter_secure_storage` and cannot participate in browser cookies). 12 numbered AC covering dual-auth precedence, silent refresh, logout cookie-clearing, CSRF exposure introduced by cookies, the `RequireAuth.tsx` pre-check that would otherwise break web login post-migration, and pre-migration session handling. Out-of-scope explicitly excludes all mobile client changes. Status: Draft — technical specification intentionally left for Architect. |
| 2026-08-11 | Architect | Technical specification filled in: API contract (dual JSON/cookie response shape gated by a new `X-Client: web` request header on `totp_confirm`/`totp_verify`/`google`/`refresh`; `/auth/refresh`'s `refresh_token` query param widened to optional with a cookie fallback — mobile contract byte-identical); RBAC matrix (unaffected — transport-only change); data model impact (none); cache/side effects (none new — existing Redis blocklist reused, CSRF token is stateless); frontend section (`apiFetch`, `RequireAuth.tsx`, plus two Architect-identified additions sharing the same broken `localStorage` pre-check pattern — `ClientLayout.tsx`, `AlreadySignedIn.tsx`); dual-auth precedence sequence diagram (AC 5). Read `backend/app/dependencies.py`, `backend/app/routers/auth.py`, `backend/app/core/rate_limit.py`, `backend/app/core/security.py`, `backend/app/config.py`, `backend/app/main.py` (CORS: `allow_credentials=True` already set, explicit origin allowlist, no wildcard — confirmed compatible with `SameSite=None` cookies), `backend/app/schemas/__init__.py`, `frontend/src/lib/api.ts`, `frontend/src/components/RequireAuth.tsx`, `frontend/src/app/ClientLayout.tsx`, `frontend/src/components/AlreadySignedIn.tsx` in full before writing. Wrote ADR-004 for the Bearer/cookie precedence rule (structural `Authorization`-header presence wins, regardless of validity — one shared signal drives both auth precedence and CSRF exemption), CSRF mechanism (stateless double-submit cookie via new ASGI middleware, not per-route dependencies), and cookie attributes (`SameSite=None`, `Secure=True`, `Path=/api/v1`, no `Domain`, host-only). Status: Draft → **Specified**. |
