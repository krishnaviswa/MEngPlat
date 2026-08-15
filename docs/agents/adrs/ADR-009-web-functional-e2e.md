# ADR-009: Web functional + technical e2e (Playwright on staging/Compose)

| Field | Value |
|-------|-------|
| **Status** | Proposed |
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

### 5. CI shape (after the suite exists)

1. Re-enable `push`/`pull_request` on `backend-tests.yml` and `frontend-tests.yml`.
2. New workflow (or job): Compose up (or equivalent service containers + Next production build), migrate, optional seed, `pytest tests/e2e`, upload traces on failure.
3. Require those checks on `main`. Until then, local `pytest` + `npm test` remains the real gate.

Cancel **stale** expensive e2e runs when a newer commit supersedes them; never skip the latest commit.

---

## Consequences

### Positive

- Second view of the product without paying vendors.
- Schema reuse prevents silent API/test drift.
- Trace Viewer is the inspection UI operators already know from Playwright.

### Negative / tradeoffs

- Python Playwright, not `@playwright/test` in `frontend/` — frontend engineers run pytest for e2e.
- SSR needs the dual-call pattern or false “no API traffic” failures.
- Compose e2e is slower than Jest; keep it on PR for `frontend/**`+`backend/**` or a nightly + `workflow_dispatch` until it is stable, then required.

### Follow-ups

- Implement `backend/tests/e2e/` per TP-S-010; gitignore traces.
- Mark this ADR Accepted when S-010 lands and README §11 “intended after S-010” commands work.
- Optional later: dedicated Railway staging project with the same mock env.

---

## Alternatives considered

1. **More Jest/RTL** — cannot see SSR, real navigation, or cross-role sequences.
2. **Cypress** — second JS toolchain; weaker reuse of Pydantic oracles.
3. **Hit production Railway** — couples tests to customer data and live keys; forbidden.
4. **Only Swagger/manual** — does not scale as slices accumulate.
