# Slice: S-091 — End-to-end merchant + admin verification (H1)

| Field | Value |
|-------|-------|
| **Slice ID** | S-091 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As** the product owner
**I want** one verification pass after the operational admin console lands
**So that** S-090 AC and the merchant/admin chains in the platform roadmap are proven together, without a Tester report per earlier slice

---

## Acceptance criteria

1. **Given** S-090 is implemented, **when** Tester runs the batched pass, **then** every S-090 AC is mapped (automated and/or the S-010 Playwright pack) and passing.
2. **Given** the merchant chain (login → identity/onboarding surfaces → listing → reviews → Google sync path → AI insights → WhatsApp card), **when** this pass runs, **then** existing Jest/pytest for S-067–S-078 plus e2e merchant flow (`test_flow_merchant.py` when `E2E=1`) are recorded as the regression evidence — no new QR/sync product work.
3. **Given** the admin chain (user search/role badges → approval queue → categories → shop reports → support tickets → `/admin` ops nav), **when** this pass runs, **then** S-079–S-090 tests plus e2e admin flow (`test_flow_admin.py` when `E2E=1`, including ops-nav assertions) are recorded.
4. **Given** this slice, **when** the report ships, **then** it is the **only** Tester report for S-090/S-091 (no TR-S-090).

---

## UX notes

- N/A (verification slice)

---

## Out of scope

- Re-authoring TR-S-086–S-089
- New product features
- Mandatory live Compose e2e in CI (S-010 remains opt-in `E2E=1`)

---

## Dependencies

- S-090 Builder complete

---

## Definition of done (PM)

- [x] TR-S-091 maps S-090 AC 1–7 and the two chains
- [x] Recommendation Ship
- [x] PM Accept S-090 and S-091

---

## Technical specification (Architect)

Verification only. No API or schema change beyond S-090.

### API contract

None.

### RBAC matrix

Covered by existing tests + S-090 AC6.

### Data model impact

- [x] None

### Frontend

Extend `backend/tests/e2e/pages/admin.py` `expect_loaded` to assert ops nav / new tiles without breaking approve/hide journey.

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-091-end-to-end-admin-merchant-pass.md`
- Test report: `docs/agents/test-reports/TR-S-091-end-to-end-admin-merchant-pass.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM / Architect | Batched H1 verification slice; no separate TR-S-090. |
| 2026-08-19 | Tester / PM | TR-S-091 Ship. Status → Accepted. |
