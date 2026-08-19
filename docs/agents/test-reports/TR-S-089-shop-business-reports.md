# TR-S-089: Shop / merchant reporting — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-089 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Signed-in create `201`, anonymous `401` (API + login redirect), own-shop `403`, repeat flag at 3, message thread for reporter and admin, `POST /reviews/{id}/report` still `200`. Review-report queue remains on `/admin`.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Signed-in shop report 201 | A | `test_create_shop_report_201_and_anonymous_401`; `ReportShopButton` submit | Pass |
| 2 | Anon → login UI + API 401 | A | same API test; `ReportShopButton` pushes `/login` | Pass |
| 3 | Own shop 403 | A | `test_merchant_cannot_report_own_shop` | Pass |
| 4 | Repeat at ≥3 | A | `test_admin_queue_flags_repeat_at_three_reports`; admin queue RTL Repeat (3) | Pass |
| 5 | Message thread both sides | A | `test_report_message_thread_visible_to_reporter_and_admin` | Pass |
| 6 | Review-report unchanged | A | `test_review_report_endpoint_unchanged`; admin page still has Reported reviews stub | Pass |

**Coverage:** 6 / 6 AC mapped

---

## Backend tests

### Added
- shop-report cases in `test_support_tickets_and_reports.py`

### Run output
Isolated processes: all cases in this file passed. See TR-S-088 for the single-process asyncpg note.

---

## Frontend tests

### Added
- `ReportShopButton.test.tsx`
- `app/admin/business-reports/__tests__/page.test.tsx`

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-089-1 | Report a shop; admin sees repeat; review queue unchanged | Not run in browser; covered by API + RTL |

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested
- [x] AI disclaimer verified (N/A)
- [x] Ready for PM acceptance
