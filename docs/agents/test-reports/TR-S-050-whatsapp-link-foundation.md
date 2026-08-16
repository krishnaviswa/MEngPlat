# TR-S-050: WhatsApp link foundation — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-050 |
| **Author** | Tester |
| **Date** | 2026-08-16 |
| **Recommendation** | Rework |

---

## Summary

Frontend RTL for the dashboard card **passed** on this host. Backend pytest in `backend/tests/test_whatsapp.py` is written against the mock provider but **was not executed here**: no Docker CLI, no host Python with FastAPI/SQLAlchemy. Do not treat mock WhatsApp as Accepted or shipped.

Honest gaps vs AC: no dedicated 401 test; Print is a button presence check only; unknown-token is silent (matches ADR, not a chat explanation).

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Card on approved dashboard beside collect QR | A | `MerchantDashboard.test.tsx` collect QR test also asserts WhatsApp heading + wa.me | Pass (Jest) |
| 2 | Unique `wa.me` + token | A | `test_merchant_gets_wa_me_link_with_token` | Not run (pytest) |
| 3 | Non-owner rejected | A | customer + other merchant tests | Not run (pytest) |
| 4 | Verify handshake | A | `TestWebhookHandshake` | Not run (pytest) |
| 5 | Missing/bad HMAC → 400 | A | `TestWebhookSignature` | Not run (pytest) |
| 6 | Valid token binds + ack | A | redeem test (bind asserted; ack is mock log) | Not run (pytest) |
| 7 | Unknown token no bind | A | `test_unknown_token_does_not_bind` | Not run (pytest) |
| 8 | Bound follow-up text does not mutate listing | A | follow-up test + redeem asserts `description is None` | Not run (pytest) |
| 9 | Mock path | A | `sha256=mock`, demo number | Not run (pytest); Jest uses fixture wa.me |
| 10 | Print for shop | A | button in `WhatsAppUpdateCard.test.tsx` | Pass (Jest, partial) |
| 11 | Unavailable empty state | A | `WhatsAppUpdateCard.test.tsx` | Pass (Jest) |

**Coverage:** 11/11 mapped; 3 frontend Pass; 8 backend **Not run**.

---

## Backend tests

### Added

- `backend/tests/test_whatsapp.py` (`TestWebhookHandshake`, `TestWebhookSignature`, `TestLinkAndRbac`, bind cases)

### Run output

```
Not executed on this workstation (docker not on PATH; WindowsApps python stub / no sqlalchemy).
Re-run: cd backend && PYTHONPATH=. pytest tests/test_whatsapp.py -q
```

---

## Frontend tests

### Added

- `WhatsAppUpdateCard.test.tsx` (2)
- `MerchantDashboard.test.tsx` WhatsApp visibility on approved vs pending

### Run output

```
PASS WhatsAppUpdateCard.test.tsx (2)
PASS MerchantDashboard.test.tsx (24) — after adding WhatsApp assertions
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Compose inbound to mock webhook | Not run (no Docker) |

---

## Gaps / rework items

1. **Execute pytest** with Postgres + alembic before PM Accept.
2. Optional: unauthenticated 401 on link POST.
3. Print window contents not asserted.

---

## Sign-off

- [x] All AC mapped to tests
- [ ] RBAC tested (tests exist, not run)
- [x] AI disclaimer n/a for S-050
- [ ] Ready for PM acceptance
