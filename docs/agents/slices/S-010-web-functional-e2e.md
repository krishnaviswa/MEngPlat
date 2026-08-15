# Slice: S-010 — Web functional e2e harness (Playwright)

| Field | Value |
|-------|-------|
| **Slice ID** | S-010 |
| **Phase** | 5 Polish |
| **Status** | In Progress |
| **Role(s)** | anonymous, customer, merchant, admin |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** maintainer  
**I want** a Playwright (Python) harness against Compose with mock vendors  
**So that** narrated product scenarios can be converted into dual-oracle browser tests without Cypress or live LLM/payment keys

---

## Acceptance criteria

1. **Given** Docker Compose is up with mock AI/email/payments and local storage, **when** `E2E=1 pytest tests/e2e` is run, **then** a smoke journey opens the home page in Chromium, asserts visible hero copy, and validates `GET /api/v1/businesses` with `BusinessResponse`.
2. **Given** default `cd backend && pytest` (no `E2E=1`), **when** the suite collects, **then** e2e tests are skipped and do not require a browser or Compose.
3. **Given** a smoke run, **when** it finishes, **then** a Playwright trace zip is written under `backend/tests/e2e/test-results/` (gitignored).
5. **Given** Compose is seeded, **when** the TP-S-010 role files run, **then** anonymous gate, customer review+logout, merchant pending listing, admin approve, and API RBAC/JWT checks execute with dual oracles.
6. **Given** a maintainer opens Actions → Web e2e (Playwright) → Run workflow, **when** the job finishes, **then** traces (and logs) are downloadable as GitHub artifacts. The workflow has no `push`/`pull_request` trigger and no deploy step.

---

## UX notes

- Not a product UI slice. Inspection UI is Playwright Trace Viewer / UI mode.
- Locators must match live copy (home h1: “Local businesses, reviewed with clarity”).

---

## Out of scope

- Branch protection / required Playwright on `main`
- Live Resend, Razorpay, OpenAI, Google OAuth
- Azure storage
- Railway staging URL (Compose on the GitHub runner is the stand-in)

---

## Dependencies

- ADR-009 (toolchain)
- TP-S-010 (oracles and layout)
- Running Compose stack for opt-in runs

---

## Definition of done (PM)

- [ ] Smoke AC verified locally when Compose is up
- [ ] Default pytest stays opt-in for e2e
- [ ] Documented in `README.md` §11
- [ ] ADR-009 Accepted when smoke exists
- [ ] `web-e2e.yml` is dispatch-only with downloadable traces (not a merge gate)

---

## Technical specification (Architect)

> See [ADR-009](../adrs/ADR-009-web-functional-e2e.md) and [TP-S-010](../test-plans/TP-S-010-e2e-flow-verification.md). This slice ships the harness + one smoke only.

### API contract

No new HTTP routes. Smoke technical oracle: `GET /api/v1/businesses` → `list[BusinessResponse]`.

### RBAC matrix

Smoke is anonymous browse only.

### Data model impact

- [x] None

### Frontend

- **Route:** `/` (SSR). Optional: first listing `/businesses/{slug}` if seed data exists.
- **Locators:** `backend/tests/e2e/pages/`

### Architect checklist

- [x] Toolchain is Playwright for Python (`pytest-playwright`), not Cypress
- [x] Mock/local vendor env for e2e
- [x] Dual oracle + SSR parallel API GET
- [x] Traces gitignored
- [x] Default pytest does not launch Chromium

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-010-e2e-flow-verification.md`
- ADR: `docs/agents/adrs/ADR-009-web-functional-e2e.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM | Thin infra slice for Playwright harness |
| 2026-08-15 | Architect | Pointed at ADR-009 / TP-S-010; smoke-only scope |
| 2026-08-15 | Builder | Manual GitHub workflow `web-e2e.yml` (Compose + traces artifact) |
