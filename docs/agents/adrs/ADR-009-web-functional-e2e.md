# ADR-009: Web functional + technical e2e (Playwright on staging/Compose)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-15 |
| **Slice** | S-010 |

---

## Context

pytest + React Testing Library cover adapters, many routers, and component behaviour. They do not prove that a real browser can complete the product loop against a running Next.js + FastAPI stack (SSR data fetching, MFA click-through, admin then merchant, mock checkout).

Slice S-010 and [TP-S-010](../test-plans/TP-S-010-e2e-flow-verification.md) already specify that second view. This ADR records the **architecture** of that testing module so Builder does not invent Cypress, hit live vendors, or treat traces without assertions as tests.

Evaluation policy for the whole product lives in `README.md` §11. This ADR is the irreversible toolchain choice.

---

## Decision

### 1. Tool: Playwright for Python (`pytest-playwright`)

- One runner with existing pytest.
- Technical oracle: `page.on("response")` plus `APIRequestContext`, validating JSON with the same Pydantic models in `backend/app/schemas`.
- Functional oracle: role/label locators and `expect()`, page objects under `backend/tests/e2e/pages/`.
- Artifacts: Playwright Tracing (`screenshots`, `snapshots`, `sources`) → gitignored `backend/tests/e2e/test-results/`. **Playwright Trace Viewer** (and locally Playwright UI mode) is the enterprise-ready UI for inspecting a failed run. Do not add Cypress, Selenium, or a custom screenshot dashboard.

### 2. Environment: Compose or staging with mock ports

Target a **spun-up** stack: frontend `:3000`, API `:8000`, Postgres, Redis.

| Variable | Staging / e2e value |
| -------- | ------------------- |
| `AI_PROVIDER` | `mock` |
| `EMAIL_PROVIDER` | `mock` |
| `PAYMENTS_PROVIDER` | `mock` |
| `STORAGE_PROVIDER` | `local` (or a disposable test bucket, not production S3) |
| `DEBUG` | `true` only where mock-complete is required; never against production |

Live Resend, Razorpay, OpenAI, and Azure are **out of e2e**. Adapter unit tests already cover those classes. Google OAuth stays a **manual** checklist item (needs a real Google account).

Users: register unique emails per run (`uuid4` suffix). Do not mutate seed demo accounts as the source of truth (seeded MFA secret may be used only for a dedicated smoke that documents that dependency).

### 3. Dual oracle and SSR

A flow step passes only if **both** UI `expect()` and API status/schema checks pass. A trace with no assertions is not a test.

Home, Search, and Business detail are Server Components — backend calls are **not** in the browser network log. Those steps use a parallel `APIRequestContext` GET (see TP-S-010).

### 4. Role journeys (minimum pack)

Anonymous browse + gated actions; customer register → review → profile → logout/blocklist; merchant create listing → dashboard; admin approve/moderate. Plus parametrized RBAC matrix from README §9.

When a **new web capability** ships, extend this pack in the same PR (and §12 parity). Do not rely on a new Jest file alone for cross-page flows.

### 5. CI shape (manual audit, not a merge gate)

Playwright is a **second view**, not a required check and not part of deploy.

1. `backend-tests.yml` / `frontend-tests.yml` stay pytest/Jest only. Re-enabling their `push`/`pull_request` triggers is a separate decision and must **not** pull in Chromium.
2. [`.github/workflows/web-e2e.yml`](../../../.github/workflows/web-e2e.yml) is **`workflow_dispatch` only**: Compose up (mock vendors) → `E2E=1 pytest tests/e2e` → always upload `playwright-traces` (and logs). No `push`, no `pull_request`, no Railway/Vercel step.
3. Operators download the artifact and open it with `playwright show-trace`. Local `pytest` + `npm test` remains the day-to-day gate.

Do not add this job to branch protection. Cancel a still-running dispatch on the same ref if a newer one is started.

---

## Consequences

### Positive

- Second view of the product without paying vendors.
- Schema reuse prevents silent API/test drift.
- Trace Viewer is the inspection UI operators already know from Playwright.

### Negative / tradeoffs

- Python Playwright, not `@playwright/test` in `frontend/` — frontend engineers run pytest for e2e.
- SSR needs the dual-call pattern or false “no API traffic” failures.
- Compose e2e is slower than Jest; it stays **manual** (`workflow_dispatch`) so product commits are not blocked. It is not a required status check.

### Follow-ups

- Harness + role journeys in `backend/tests/e2e/` (`E2E=1`). Gitignore traces.
- Manual GitHub job: `web-e2e.yml` (Compose + Chromium + artifact traces).
- Optional later: dedicated Railway staging with the same mock env (still not production, still not auto-on-PR).

---

## Alternatives considered

1. **More Jest/RTL** — cannot see SSR, real navigation, or cross-role sequences.
2. **Cypress** — second JS toolchain; weaker reuse of Pydantic oracles.
3. **Hit production Railway** — couples tests to customer data and live keys; forbidden.
4. **Only Swagger/manual** — does not scale as slices accumulate.
