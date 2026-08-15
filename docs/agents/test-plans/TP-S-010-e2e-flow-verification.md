# TP-S-010: End-to-end functional + technical flow verification — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-010 (Test hardening + deploy verification) |
| **Author** | Tester |
| **Date** | 2026-08-09 |

> **Process note:** S-010 is a backlog row (`README.md` §13) with no PM slice brief or
> Architect spec yet — it's infra/tooling, not a feature vertical slice, so there's no
> per-feature Acceptance Criteria to map against. The "AC → planned tests" table below
> uses this plan's own numbered objectives in place of PM-authored AC. If this needs to
> go through the full PM → Architect gate later, split it into its own slice.

---

## Scope

A repeatable, automated Playwright (Python) suite that, for each role (anonymous,
customer, merchant, admin):

1. Logs in (or stays anonymous) and clicks through the app's real pages in order.
2. Records a full trace of the session — screenshots, DOM snapshots, and every API
   call with its network timing.
3. Asserts the **functional** flow (right content, right redirects, forms actually
   submit) and the **technical** flow (right endpoint sequence, right status codes,
   right response shape) at the same time, from the same run.
4. Asserts the **auth/security chain**: JWT claim correctness, `type` enforcement
   (access vs. refresh), RBAC per `README.md` §9, ownership checks (404-not-403), and
   token-blocklist-on-logout.
5. Produces a per-endpoint timing report so slow calls are visible without a separate
   perf tool.

Out of scope: load/stress testing (this is single-session functional+security, not
concurrency); full Google OAuth (needs live Google creds — stays a manual check);
upload MIME/size limits (tracked as an unmitigated gap in §9, not something to assert
against until it's implemented).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Browser click-through | Playwright (Python) + `pytest-playwright` | Real page navigation per role, UI assertions (redirects, hidden actions, form results) |
| Recording | Playwright Tracing (`context.tracing.start(screenshots=True, snapshots=True, sources=True)`) | One `trace.zip` per test, viewable in Trace Viewer — this *is* the "conversation" record, no custom logger needed |
| API timing | `page.on("response")` → `response.request().timing()` | Per-call `{method, url, status, duration_ms}` collected into a JSON report; flag anything over a threshold (e.g. 1000ms) |
| Pure API / RBAC matrix | Playwright `APIRequestContext` (`playwright.request`, no browser) | Fast negative-auth matrix — doesn't need a page for a 401/403/404 check |
| Token/claims | `PyJWT` (`jwt.decode(token, options={"verify_signature": False})` for structure, or with `SECRET_KEY` from the test env for a real signature check) | Assert `sub`, `exp`, `type`, `role` claims and that `type` is enforced correctly |
| Backend unit/integration | existing `pytest` + `httpx.AsyncClient` (`backend/tests/`) | Stays as-is — this plan doesn't duplicate router-level tests, only adds the cross-cutting flow layer |

Suggested layout:

```
backend/tests/e2e/
  conftest.py              # role fixtures: register+login → {page, access_token, refresh_token}
  test_flow_anonymous.py
  test_flow_customer.py
  test_flow_merchant.py
  test_flow_admin.py
  test_rbac_matrix.py      # parametrized over README §9 table, uses APIRequestContext
  test_token_security.py   # claim shape, type enforcement, blocklist-after-logout
  report.py                # merges timing + trace paths into one JSON/HTML summary per run
```

Test users are created via `/auth/register` inside fixtures with a `uuid4()`-suffixed
email each run, not the seeded demo data — keeps the suite idempotent and re-runnable
without mutating `scripts/seed.py` data.

---

## Click, capture, and compare mechanics

"Browser click-through" above was underspecified — this makes explicit how a page
actually gets navigated, what "capture" produces, and what decides pass vs. fail. A
click-through with no assertions only proves nothing crashed, not that anything is
*correct*, so this section exists to stop that gap from reaching implementation.

### Navigation & clicking

- Locators are role/label/text-based — `page.get_by_role("button", name="Submit review")`,
  `page.get_by_label("Email")` — never raw CSS/XPath. They survive markup changes and
  match what a user actually perceives, not an implementation detail of the DOM.
- Each page gets one shared locator helper (e.g. `pages/business_detail.py`,
  `pages/merchant_dashboard.py`) so a selector only needs fixing in one place when the
  UI changes, not in every test that touches that page.
- Playwright's `expect()` auto-waits and retries up to a timeout instead of a fixed
  `sleep` — clicking through pages doesn't need manual waits for navigation or the
  API call behind it to finish.

### Content capture — three layers, automatic once tracing is on

1. **Trace** (`context.tracing.start(screenshots=True, snapshots=True, sources=True)`)
   — a screenshot + full DOM snapshot at every action, replayable step-by-step in
   Trace Viewer. This *is* the "conversation" record from the original ask — nothing
   extra to write for it.
2. **Structured extraction for assertions** — not a full-page dump on every step, but
   targeted reads: `locator.inner_text()`, `expect(locator).to_have_text(...)`,
   `page.get_by_role(...)` counts. Full-page HTML (`page.content()`) is captured only
   on failure, so passing-run artifacts stay small.
3. **Network** — every `response` event captured as `{url, method, status, timing,
   json body}`. This is the technical-flow record (§ Test strategy, API timing row).

### The oracle — how "aligns with expectation" actually gets decided

Two independent comparisons, each needing an explicit expected value written into the
test — this is the part that isn't generated automatically and has to be authored per
flow step:

- **Functional oracle:** UI-level `expect()` assertions against what the page *should*
  show. E.g. after submitting a review: `expect(page.get_by_test_id("review-card").last).to_contain_text(submitted_text)`
  and `expect(page.get_by_text("AI-analyzed")).to_be_visible()`. Requires `data-testid`
  on the components in question — check which already exist before assuming coverage.
- **Technical oracle:** captured response JSON validated against the same Pydantic
  response models the backend already defines (`UserResponse`, `BusinessResponse`,
  `TokenResponse` in `backend/app/schemas`) via `.model_validate(response_json)`,
  plus an explicit expected status code per the RBAC table above. Reusing the
  backend's own schemas as the oracle — instead of hand-writing a second JSON schema
  — means the check breaks the moment backend and test drift apart rather than the
  two silently diverging.

A flow test is "aligned" only when both oracles pass for every step; a trace with no
`expect()` calls is a recording, not a test.

### Callout: SSR pages hide their backend call from the browser

Per `frontend/CLAUDE.md`, Home, Search, and Business detail are **Server Components** —
`businesses.list()` / `businesses.search()` / `businesses.get()` run in the Next.js
server process during render, so the backend call never crosses the browser's network
stack. `page.on("response")` will **not** see `GET /api/v1/businesses` for these three
pages — it only sees the navigation request to Next.js on `:3000`. Every other page in
scope (`/login`, `/register`, `/businesses/[slug]/review`, `/profile`, `/settings`,
`/merchant/dashboard`, `/merchant/businesses/*`, `/admin`) is a Client Component calling
`apiFetch` directly, so those API calls **are** browser-visible.

For the three SSR pages, the technical oracle can't come from `page.on("response")` —
it has to come from an equivalent direct call through Playwright's `APIRequestContext`
(no browser) hitting the same endpoint, run alongside the UI check rather than
extracted from it.

---

## Per-flow expectation sketch (functional + technical)

Concrete `expect()` and schema/status checks per step, grounded in the actual
components and routers (button text, placeholders, endpoints, and schemas below are
copied from the current code, not invented). This is the level of detail each
`test_flow_*.py` needs — anything vaguer than this table isn't implementable yet.

### Anonymous — `test_flow_anonymous.py`

| # | Action | Functional oracle | Technical oracle |
|---|--------|--------------------|-------------------|
| 1 | Navigate to `/` | `expect(page.get_by_role("heading", name="Support local businesses you trust"))` visible; at least one `a[href^="/businesses/"]` card rendered | **SSR — not browser-visible.** Parallel `APIRequestContext.get("/api/v1/businesses")` → 200, validates `list[BusinessResponse]`; `.get("/api/v1/search/businesses?city=Chennai")` → 200, same schema |
| 2 | Click **"View all in Chennai →"** | `expect(page).to_have_url(re.compile(r"/search\?city=Chennai"))` | **SSR.** `APIRequestContext.get("/api/v1/search/businesses?city=Chennai")` → 200; every item's `city` field matches "Chennai" case-insensitively (filter correctness, not just shape) |
| 3 | Click a business card → `/businesses/{slug}` | `expect(page.get_by_role("heading", level=1, name=business.name))` visible; `expect(page.get_by_role("link", name="Write a review")).to_have_attribute("href", f"/businesses/{slug}/review")` | **SSR.** `.get("/api/v1/businesses/{slug}")` → 200, `BusinessResponse.status == "approved"`; `.get("/api/v1/reviews/business/{business_id}")` → 200, `list[ReviewResponse]` |
| 4 | Click **"Write a review"** while signed out | `expect(page.get_by_text("Sign in to write a review.")).to_be_visible()`; `expect(page.get_by_role("link", name="Sign in")).to_have_attribute("href", "/login")` | Browser-visible, negative check: assert **no** `POST /api/v1/reviews` appears in the captured response log for this step — the gate is enforced client-side (checks `localStorage["access_token"]`) before any request is attempted |
| 5 | Click **"Sign in"** → `/login` | `expect(page.get_by_placeholder("Email"))`, `expect(page.get_by_placeholder("Password"))`, `expect(page.get_by_role("button", name="Sign in"))` all visible | — |

### Customer — `test_flow_customer.py`

| # | Action | Functional oracle | Technical oracle |
|---|--------|--------------------|-------------------|
| 1 | `/register`: fill "Full name" / "Email" / "Password (min 8 chars)", leave role = "Customer — discover & review", click **"Sign up"** | Hard nav to `/` (`window.location.href`): `expect(page).to_have_url(f"{FRONTEND_URL}/")` | `POST /api/v1/auth/register` → 201, `UserResponse`, `role == "customer"`; then `POST /api/v1/auth/login` → 200, `TokenResponse`; decode `access_token` → `type == "access"`, `role == "customer"`, `sub` == the registered user's `id` |
| 2 | Navigate to a seeded approved business, click **"Write a review"** | `expect(page.get_by_placeholder(re.compile("Share details")))` visible (form renders, not the sign-in prompt) | Confirms step 1's token is honored — no `/login` redirect |
| 3 | Click the `"5 stars"` rating button (`RatingWidget` renders `aria-label="{n} stars"`), fill the review textarea (≥10 chars), click **"Post review"** | Client nav to `/businesses/{slug}` (`router.push`, no reload): `expect(page).to_have_url(f"{FRONTEND_URL}/businesses/{slug}")`; new card shows `expect(page.get_by_text("AI: ")).to_be_visible()` and the submitted body text is present | `POST /api/v1/reviews` → 201, `ReviewResponse`; assert `ai_analysis` is non-null and `ai_analysis.sentiment` ∈ `{positive, neutral, negative}` (proves the AI pipeline ran, not just that the row was written); assert `author_id == sub` from step 1's token — this is the concrete "JWT chain authorized the right identity" check |
| 4 | Navigate to `/profile` | Page renders the profile card, not `Please login.` — proves the token from step 1 is still valid | `GET /api/v1/auth/me` → 200, `UserResponse`; `id`/`role` match step 1's token claims |
| 5 | Navigate to `/settings`, then trigger logout | (Note: confirm the actual logout control's label/location in `SettingsPage.tsx`/`Navbar.tsx` before writing the test — not yet verified against this plan's source pass) | `POST /api/v1/auth/logout` with `Authorization: Bearer {access_token}` → 200, `MessageResponse` |
| 6 | Immediately replay the **same** (now logged-out) access token via `APIRequestContext.get("/api/v1/auth/me")` | — | Expect **401** — this is the blocklist-on-logout check; without it step 5 only proves the endpoint returned 200, not that the token actually stopped working |

### Merchant — `test_flow_merchant.py`

| # | Action | Functional oracle | Technical oracle |
|---|--------|--------------------|-------------------|
| 1 | Register with role = "Merchant — list my business", login | Hard nav to `/merchant/dashboard` (merchant role redirects here, not `/`) | Same claim checks as customer step 1, plus `role == "merchant"` |
| 2 | `/merchant/dashboard` with no businesses yet | `expect(page.get_by_text("No business yet")).to_be_visible()`; `expect(page.get_by_role("link", name="Create your business"))` visible | `GET /api/v1/businesses/mine` → 200, `[]` |
| 3 | `/merchant/businesses/new`: fill "Business name *"/"Street address *"/"City *", click **"Submit for approval"** | `expect(page.get_by_text("New listings start as pending"))` was visible pre-submit; `onSuccess` fires (confirm redirect target in `new/page.tsx` before writing) | `POST /api/v1/businesses` → 201, `BusinessResponse`, `status == "pending"` |
| 4 | Back on `/merchant/dashboard`, business now selected | `expect(page.get_by_text("Awaiting approval")).to_be_visible()` (amber `STATUS_LABEL.pending`); stat tiles "Total reviews" = 0, "Average rating" = 0.0 | `GET /api/v1/dashboard/merchant/{business_id}` → 200, `DashboardStats`; `GET /api/v1/ai/businesses/{business_id}/insights` → 200 |
| 5 | *(Requires an admin to approve first — cross-flow dependency, see Edge cases)* Reply to a customer review: click **"Reply as business"**, fill textarea (≥5 chars), click **"Post reply"** | `expect(page.get_by_text("Response from the business")).to_be_visible()` with the reply body | `POST /api/v1/reviews/{review_id}/reply` → 201, `ReplyResponse` |
| 6 | Attempt an admin-only action directly (e.g. `POST /businesses/{id}/approve` on any business) via `APIRequestContext` using the merchant's token | — | 403 — confirms role check, not just UI hiding the button |
| 7 | Attempt `PATCH /businesses/{other_merchant_business_id}` (a business this merchant doesn't own) via `APIRequestContext` | — | **404**, not 403 — the ownership check in `update_business()` re-queries `Business.merchant_id == merchant.id` and 404s rather than leaking that the business exists |

### Admin — `test_flow_admin.py`

| # | Action | Functional oracle | Technical oracle |
|---|--------|--------------------|-------------------|
| 1 | Login as admin, navigate to `/admin` | `expect(page.get_by_role("heading", name="Admin Panel"))` visible; stat tiles for all 5 `PlatformStats` keys render | `GET /api/v1/dashboard/admin/platform` → 200, `PlatformAnalytics` |
| 2 | In "Pending businesses" section, click **"Approve"** on the merchant's business from the Merchant flow | Card disappears from the pending list; stats refresh (`onChange` callback fires `loadStats()` again) | `POST /api/v1/businesses/{id}/approve` → 200, `BusinessResponse`, `status == "approved"`; assert an `audit_logs` row was written for `action="approve"` (via a direct DB check in the fixture teardown, not through the UI) |
| 3 | In "Reported reviews" section (seed one via the customer's **"Report"** button first), click **"Hide"** | Card disappears from the queue | `POST /api/v1/reviews/{id}/moderate?action=hide` → 200, `MessageResponse`; follow-up `GET /api/v1/reviews/business/{business_id}` no longer includes it (status moved to `hidden`, excluded by the `status == ACTIVE` filter) |
| 4 | Attempt `GET /api/v1/businesses?status_filter=pending` as the **customer** role via `APIRequestContext` | — | 403 — confirms the non-approved `status_filter` admin gate in `list_businesses()` |

---

## AC → planned tests

| # | Objective | Test approach | Test ID / file |
|---|-----------|----------------|-----------------|
| 1 | Anonymous can browse home/search/business detail; protected actions redirect to `/login` | Automated (browser) | `test_flow_anonymous.py::test_anonymous_browse_and_redirect` |
| 2 | Customer: register → login → browse → submit review → AI analysis returned → appears in `/profile` → logout | Automated (browser) | `test_flow_customer.py::test_customer_full_journey` |
| 3 | Merchant: login → dashboard → create business → edit own business → reply to review → AI insights/analytics load | Automated (browser) | `test_flow_merchant.py::test_merchant_full_journey` |
| 4 | Admin: login → approve/suspend business → moderate review → platform analytics | Automated (browser) | `test_flow_admin.py::test_admin_full_journey` |
| 5 | Every API call in each journey matches the RBAC table in §9 (right status per role) | Automated (API matrix) | `test_rbac_matrix.py::test_rbac_matrix[*]` |
| 6 | Ownership violation returns 404, not 403 (merchant B editing merchant A's business) | Automated (API) | `test_rbac_matrix.py::test_ownership_returns_404_not_403` |
| 7 | Access token: `sub`/`exp`/`type=access`/`role` claims all present and correct after login | Automated | `test_token_security.py::test_access_token_claims` |
| 8 | Refresh token cannot be used on a protected endpoint (`type` enforcement) | Automated | `test_token_security.py::test_refresh_token_rejected_on_protected_route` |
| 9 | After `/auth/logout`, the same access token is rejected on the next call (blocklist) | Automated | `test_token_security.py::test_logout_blocklists_token` |
| 10 | Every recorded API call's timing is captured and a per-endpoint summary (min/max/p95) is produced | Automated (report) | `report.py` output, asserted non-empty in `test_flow_*` teardown |

---

## RBAC test cases

Directly from `README.md` §9's authorization table — each row becomes one parametrized case in `test_rbac_matrix.py`:

| Case | Role | Endpoint / action | Expected |
|------|------|--------------------|----------|
| Unauthenticated write | none | `POST /reviews` | 401 |
| Unauthenticated dashboard | none | `GET /dashboard/merchant` | 401 |
| Wrong role — create business | customer | `POST /businesses` | 403 |
| Wrong role — approve business | merchant | `PATCH /businesses/{id}/approve` | 403 |
| Wrong role — moderate review | merchant | `POST /reviews/{id}/moderate` | 403 |
| Wrong role — platform analytics | customer, merchant | `GET /analytics/platform` | 403 |
| Ownership — edit another merchant's business | merchant (not owner) | `PATCH /businesses/{id}` | 404 (not 403 — must not leak existence) |
| Ownership — reply to review on another's business | merchant (not owner) | `POST /reviews/{id}/reply` | 404 |
| Author-scoped — edit another user's review | customer (not author) | `PATCH /reviews/{id}` | 403/404 per router |
| Inactive account login | suspended user | `POST /auth/login` | 403 |
| Google-only account, password login | google user | `POST /auth/login` | 400 |
| Expired access token | any | any protected route | 401 |
| Refresh token used as access token | any | any protected route | 401 "Invalid token type" |
| Blocklisted (logged-out) token reused | any | any protected route | 401 |

---

## Edge cases

- Registering with an already-used email → 409, and the flow stops there (no tokens issued).
- Self-registering as `admin` via `/auth/register` → 403, confirmed no admin account is created.
- Anonymous clicking "Favorite" or "Write a review" on a business detail page → frontend redirects to `/login` (UI-level check, not just the API 401).
- Approving/moderating an already-approved/removed item → verify it doesn't double-write an audit log row.
- Trace capture itself doesn't leak tokens into artifacts committed to the repo — trace/video output should go to a gitignored `test-results/` dir, not `docs/`.

---

## Manual checklist (if applicable)

- [ ] M-001: Full Google OAuth sign-in with a live Google test account (client-side ID token flow can't be scripted headlessly without real Google credentials)
- [ ] M-002: Visual smoke of `docker compose up --build` cold start (frontend 3000, backend 8000, postgres 5432, redis 6379 all healthy)

---

## Environment

- `AI_PROVIDER=mock` (no network calls to a real AI provider during the run)
- `docker compose up --build` running (frontend `:3000`, backend `:8000`)
- `playwright install chromium` (one-time browser binary install)
- Base URLs: `FRONTEND_URL=http://localhost:3000`, `API_URL=http://localhost:8000/api/v1`
- GitHub: Actions → **Web e2e (Playwright)** (`web-e2e.yml`) is `workflow_dispatch` only. Download artifact `playwright-traces`; inspect with `playwright show-trace`. Not on push/PR and not a deploy step.
- `SECRET_KEY` available to the test process if doing real JWT signature verification (must match the backend's — see §9 known weakness #2 on the default secret)
- Trace/report output → `backend/tests/e2e/test-results/` (add to `.gitignore` if not already covered)
