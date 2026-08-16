# TR-S-052: WhatsApp AI text drafts — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-052 |
| **Author** | Tester |
| **Date** | 2026-08-16 |
| **Recommendation** | Rework |

---

## Summary

Dashboard Apply/Discard RTL **passed**. Backend draft/apply/discard/RBAC tests exist and were **not run**. Product AC prefers per-field Apply; UI applies the **whole draft** (API `fields` optional). Extract failure still sends `Got it, thanks!` with no dashboard row — AC8 only partly met.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Pending draft, live row unchanged | A | `test_token_redeems_and_text_creates_pending_draft` | Not run |
| 2 | Panel + suggestion labels + Apply/Discard | A | `WhatsAppDraftsPanel.test.tsx` | Pass (Jest) |
| 3 | Apply writes live fields | A | `test_apply_writes_live_fields` | Not run; UI is whole-draft |
| 4 | Discard | A | `test_discard_does_not_change_listing` | Not run |
| 5 | Customer 403 | A | `test_customer_cannot_list_or_apply_drafts` | Not run |
| 6 | Empty extract → no fake fields | — | no dedicated test; code skips empty `fields` | Unproven |
| 7 | Degraded banner; no auto-apply | A | panel `degraded` copy; Apply is a click | Pass (Jest, degraded banner untested if `degraded: false` fixture) |
| 8 | Extract failure does not 500 ingest | — | webhook catches extract errors; ack still success | Gap vs AC copy |
| 9 | Admin can list | A | `test_admin_can_list_drafts` | Not run (apply-as-admin not asserted) |

**Coverage:** 9/9 mapped; mixed Pass / Not run / Gap.

---

## Backend tests

### Added

- `TestDrafts` + redeem/follow-up in `test_whatsapp.py`

### Run output

```
Not executed on this host.
```

---

## Frontend tests

### Added

- `WhatsAppDraftsPanel.test.tsx` (3 tests)

### Run output

```
PASS WhatsAppDraftsPanel.test.tsx (3)
```

---

## Gaps / rework items

1. Run pytest before Accept.
2. Distinct WhatsApp ack (or dashboard toast) when extraction fails (AC8).
3. Per-field Apply UI if PM still wants it (API already supports `fields`).
4. Jest case with `degraded: true`.

---

## Sign-off

- [x] All AC mapped
- [ ] RBAC executed
- [x] AI disclaimer on panel
- [ ] Ready for PM acceptance
