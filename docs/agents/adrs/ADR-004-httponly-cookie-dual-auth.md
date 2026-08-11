# ADR-004: httpOnly cookie auth for web, dual Bearer/cookie backend, stateless CSRF

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Slice** | S-026 |

---

## Context

Today (`frontend/src/lib/api.ts`, `backend/app/dependencies.py`, `backend/app/routers/auth.py`)
the web app stores `access_token`/`refresh_token` in `localStorage` and attaches them as
`Authorization: Bearer` on every request; the backend authenticates purely via
`HTTPBearer(auto_error=False)`. Any XSS on the site can read `localStorage` and exfiltrate both
tokens (README §9 "Known weaknesses" row 1). The Flutter mobile app
(`mobile/lib/core/storage/token_storage.dart`, `mobile/lib/core/network/auth_interceptor.dart`)
uses the same Bearer mechanism via `flutter_secure_storage` and has no meaningful way to
participate in browser httpOnly cookies — mobile changes are explicitly out of scope for S-026.

This forces a **dual-auth** backend: the same endpoints (`login`'s MFA gate, `totp_confirm`,
`totp_verify`, `google`, `refresh`, and every `require_roles`-gated route downstream) must
authenticate a browser via an httpOnly cookie and a mobile client via a Bearer header,
simultaneously, indefinitely (mobile cannot be migrated away from Bearer). The slice brief
(`docs/agents/slices/S-026-httponly-cookie-auth-migration.md`) explicitly deferred three
decisions to this ADR:

1. What happens when a single request carries **both** a valid Bearer header and a valid auth
   cookie (AC 5) — must be deterministic and testable, not undefined behavior.
2. What defends cookie-authenticated state-changing requests against CSRF (AC 9), given browsers
   auto-attach cookies to cross-site requests but never auto-attach an `Authorization` header.
3. `SameSite`/`Domain`/`Path` cookie attributes, given `frontend/src/lib/api.ts`'s `API_URL`
   split (`NEXT_PUBLIC_API_URL` vs `API_URL_INTERNAL`) and README §10's deployment options
   (Railway: separate frontend/backend services on different subdomains; Option C: Vercel +
   Render on entirely different domains) mean frontend and backend are **cross-origin in every
   documented deployment topology**, not just in local dev.

A fourth, closely related design gap surfaced during this ADR that the brief didn't anticipate:
the backend has no way to know, at the four token-issuing endpoints, whether the caller is the
web frontend (which must get `Set-Cookie` + no tokens in the body per AC 1) or the mobile app
(which must keep getting tokens in the JSON body per AC 2) — both call the *same* endpoints.
That decision is folded into this ADR too, since it's inseparable from the precedence question.

## Decision

### 1. Bearer wins when present — structurally, not just when valid

`get_current_user` (and `get_optional_user`, and `logout`, which today hard-requires Bearer via
`Depends(security)`) resolve the token as: **if the `Authorization` header is present at all,
use only that value; fall back to the `access_token` cookie only when no `Authorization` header
was sent.** "Present" means structural presence of the header, not whether it later decodes
successfully — a request with a garbage Bearer value and a valid cookie still gets a `401` from
the Bearer path; it does **not** fall through to the cookie. One shared signal
(`"authorization" in request.headers`) drives both this precedence rule and the CSRF exemption
in decision 2, so the two checks can never disagree about which transport a request is using.

### 2. CSRF: stateless double-submit cookie, enforced by ASGI middleware

A new non-`HttpOnly` `csrf_token` cookie (`secrets.token_urlsafe(32)`, no server-side storage)
is set alongside the two session cookies at every issuance point. New middleware
(`app/core/csrf.py`, registered in `main.py` after `CORSMiddleware`) rejects any
`POST`/`PUT`/`PATCH`/`DELETE` request with `403` when: no `Authorization` header is present
**and** an `access_token` or `refresh_token` cookie is present **and** the `X-CSRF-Token`
request header is missing or doesn't equal the `csrf_token` cookie. Bearer-authenticated
requests (mobile) skip the check entirely, per AC 9's explicit exemption and decision 1's shared
signal.

Implemented as middleware, not a per-route `Depends`, because the requirement is genuinely
cross-cutting — every mutating route across `businesses`, `reviews`, `photos`, `favorites`,
`notifications`, plus `auth` itself, needs identical treatment, and a dependency would mean
touching ~10 router files' signatures for one uniform rule.

### 3. Cookie attributes: `SameSite=None; Secure; Path=/api/v1`, no `Domain`

- **`SameSite=None`** (not `Lax`/`Strict`): frontend and backend are cross-origin in every
  deployment topology this repo documents (README §10 — separate Railway services, or
  Vercel+Render on unrelated domains), so a `Lax`/`Strict` cookie would simply never be sent on
  the browser's cross-origin `fetch` calls to the API, breaking the feature entirely in every
  real deployment while appearing to work in local dev (same registrable domain, different
  ports only). `SameSite=None` requires `Secure`, which we already need per AC 1.
- **`Secure=True`**, unconditionally, no environment toggle. Modern Chrome/Firefox/Edge treat
  `http://localhost` (though not `http://127.0.0.1` uniformly) as a secure context, so `Secure`
  cookies work over plain HTTP in local Compose dev (`NEXT_PUBLIC_API_URL=http://localhost:8000`
  per README, already `localhost`, not `127.0.0.1`). Production is HTTPS-only per README §10
  (Out of scope of this slice, but assumed).
- **No `Domain` attribute** (host-only cookie): `Domain` only helps when frontend and backend
  share a registrable parent domain and cookies need to fan out across subdomains — not the case
  in any topology here. Omitting it is both the simpler and the more restrictive/secure default.
- **`Path=/api/v1`** for all three cookies (uniform, not narrowed per-cookie): this API's entire
  surface mounts under that prefix, so it's the natural scope. A narrower `Path` for
  `refresh_token` alone (e.g. `/api/v1/auth`) was considered and rejected — see Alternatives.

### 4. Web/mobile response-shape signal: `X-Client: web` request header

`frontend/src/lib/api.ts`'s `apiFetch` sends `X-Client: web` on every request. The four
token-issuing endpoints branch on it: present → set cookies, omit `access_token`/`refresh_token`
from the JSON body (`TokenResponse` fields become `str | None = None` +
`response_model_exclude_none=True`); absent (mobile, curl, Swagger `/docs`) → unchanged JSON
body, no cookies. This is what makes AC 1 (web: no tokens in body, not in `localStorage`) and
AC 2 (mobile: unchanged JSON body) both true on the literal same route.

## Consequences

### Positive

- One shared signal (`Authorization` header presence) resolves both the auth-precedence
  question and the CSRF-exemption question — no separate rule to keep in sync, no scenario
  where a request is "Bearer for auth but cookie for CSRF purposes" or vice versa.
- Mobile's contract is provably unaffected: it never sends `X-Client: web`, so it always hits
  the "unchanged JSON body, no cookies" branch; it always sends `Authorization`, so it always
  hits the "Bearer wins, cookie never consulted, CSRF exempt" branch. Zero mobile source diff
  required, confirming the brief's Out-of-scope constraint by construction, not by convention.
- CSRF-as-middleware means zero router files need a new per-route dependency; the ~10 affected
  routers (`businesses`, `reviews`, `photos`, `favorites`, `notifications`, `auth`, etc.) need
  no code changes for CSRF at all.
- `SameSite=None` + strict CORS origin allowlist (`allow_credentials=True`, explicit
  `cors_origin_list`, no wildcard — already true in `main.py` pre-slice) + double-submit CSRF is
  three independent layers against the two realistic attack shapes (XSS token theft via AC 1's
  `HttpOnly`; pure CSRF via AC 9's token check; cross-origin `fetch`-based CSRF via CORS
  rejecting the preflight).

### Negative / tradeoffs

- **`SameSite=None` cookies are third-party cookies from the browser's perspective** whenever
  frontend and backend are cross-site (true in every deployment topology here). Safari ITP,
  Firefox strict tracking protection, and Chrome's phased third-party-cookie deprecation can all
  silently drop `Set-Cookie` while the login response itself still returns `200` — this is
  exactly the edge case the slice brief's UX notes flag ("browser blocks first-/third-party
  cookies ... leaving the user effectively logged out on the very next request"). This slice's
  mitigation is a visible error state, not a structural fix; the structural fix (same-origin
  deployment via a reverse proxy or a shared parent domain) is a deployment-topology change,
  out of scope here. Flagged as a follow-up below.
- **Stateless double-submit CSRF is weaker than a session-bound/HMAC-signed double-submit
  token.** A naive stateless double-submit is theoretically defeatable by an attacker who can
  already set arbitrary cookies for our domain (e.g. via a subdomain takeover, response-header
  injection, or a network MITM on a non-HTTPS hop) — at which point they could set their own
  matching `csrf_token`/header pair. This threat requires a capability beyond plain CSRF (no
  XSS, no cookie-setting foothold), and is explicitly out of this slice's threat model; the
  stronger HMAC-bound variant needs a server-side session concept, which is explicitly out of
  scope for this slice (brief's Out-of-scope: "server-side session store ... unless the
  JWT-in-cookie approach is unworkable" — it isn't).
- **`get_current_user`/`get_optional_user`/`logout` all need `Request` threaded through** to
  read `request.cookies` — a small, mechanical signature change repeated at three call sites in
  `dependencies.py`/`auth.py`, not a design risk but worth flagging so Builder doesn't miss one
  of the three.
- Structural (not decoded) `Authorization`-header-presence as the precedence signal means a
  client that sends a **broken** Bearer header alongside a **valid** cookie gets a `401`
  instead of successfully falling back to the cookie. Accepted: this is the more predictable,
  more testable behavior (AC 5 asks for exactly this), and no real client in this system sends
  a header it doesn't intend to be used — mobile always sends a valid one when authenticated,
  web (post-migration) never sends one at all.

### Follow-ups

- If a `SameSite=None` third-party-cookie-blocking failure rate turns out to be material in
  practice (real users, not just the UX-notes hypothetical), the durable fix is a same-origin
  deployment: the frontend reverse-proxies `/api/*` to the backend (or both are placed under one
  parent domain), making the auth cookie first-party/same-site and allowing `SameSite=Lax`
  instead. That's an infrastructure/topology decision for a separate slice + ADR, not a code
  change to this one.
- If a future slice adds a server-side session concept for any other reason, revisit the CSRF
  token to bind it to that session (HMAC-signed double-submit) instead of the current
  stateless/unbound version — strictly stronger, no reason not to once the session store exists.
- `X-Client: web` is a coarse, cooperative signal (the frontend asserts "I am the web app"; it
  is not itself a security boundary — nothing prevents a non-browser client from sending it too).
  That's fine for its actual purpose here (choosing *response shape*, not granting *authority* —
  a caller that sends `X-Client: web` without a real browser cookie jar just gets cookies it
  can't use and a body with no tokens, i.e. it locks itself out, not a privilege gain). Worth
  restating if this header is ever repurposed for anything auth-relevant later — it must not be.

## Alternatives considered

1. **Cookie wins over Bearer when both present.** Rejected: inverts the "explicit signal beats
   ambient signal" intuition (a client that deliberately constructs an `Authorization` header is
   expressing clear intent; a cookie is attached automatically by the browser whether the caller
   wanted it there or not) and offers no advantage — nothing in this system's client set ever
   benefits from cookie-over-Bearer precedence.
2. **Synchronizer-token CSRF pattern (token embedded in a server-rendered form / fetched via a
   dedicated endpoint and validated server-side against a stored value).** Rejected: this
   backend has no server-side session store for the JWT flow (by design, out of scope to add
   one), so "stored value" would need its own new state (e.g. a Redis entry keyed by something),
   adding infrastructure this slice doesn't otherwise need. Double-submit is the standard
   stateless-JWT-compatible CSRF pattern for exactly this shape of system.
3. **Custom-header-only CSRF check (no cookie comparison — just require *some* `X-Requested-With`
   or similar header on mutating requests, without a matching-value check).** Rejected: this is
   a real, commonly used CSRF mitigation (plain HTML forms can't set custom headers, so it does
   block form-based CSRF), but it's weaker than double-submit against a `fetch`-based attacker
   who *can* set arbitrary headers from a page that CORS would otherwise block only the
   *response-reading*, not the *sending*, of a "simple" request. Double-submit additionally
   requires knowing a value isolated by the browser's same-origin cookie policy, closing that
   gap for no extra runtime cost.
4. **`SameSite=Lax` with a same-origin dev proxy assumed for production.** Rejected for *this*
   slice: it would require also deciding and building a reverse-proxy/shared-domain deployment
   topology, which is explicitly the kind of infrastructure work the brief's Out-of-scope
   section excludes ("HTTPS/TLS termination infrastructure work"). Captured as a Follow-up
   instead of blocking this slice on an infra decision.
5. **Per-route CSRF `Depends()` instead of ASGI middleware.** Rejected: the rule is identical
   across every mutating route in the system (cookie-authenticated + mutating verb → check
   header), so a dependency would mean editing every router's mutating route signatures for a
   rule that has zero per-route variation — middleware is less code, less drift risk, and
   `backend/CLAUDE.md`'s "routers thin, logic in services" principle doesn't have an obvious
   place for a cross-cutting request-level check like this anyway.
6. **Narrower `Path=/api/v1/auth` for the `refresh_token` cookie specifically** (vs. the
   `/api/v1` used for all three). Considered as a defense-in-depth reduction of where the
   longest-lived cookie travels over the wire. Rejected for this slice in favor of one uniform
   `Path` for all three cookies — simpler mental model, fewer attribute combinations for Tester
   to verify, smaller diff. Noted here in case a future hardening pass wants to revisit it.
7. **Always include tokens in the JSON body regardless of caller** (drop AC 1's "not present in
   the JSON body" requirement, rely on `HttpOnly` alone). Rejected: AC 1 is explicit and for good
   reason — even though `HttpOnly` prevents `document.cookie` access, the web page's *own*
   `fetch()` call would still receive the token in its response body if included, and an XSS
   payload that hooks `window.fetch`/`XMLHttpRequest` before the app code runs could intercept
   and exfiltrate it there, before it's ever "stored" anywhere. Omitting it from the body closes
   that gap; that's the entire reason decision 4 (the `X-Client: web` signal) exists.
