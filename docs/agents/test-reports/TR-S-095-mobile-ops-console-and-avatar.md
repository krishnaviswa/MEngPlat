# TR-S-095: Mobile ops console + avatar — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-095 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

Admin Home extras (open tickets, repeat shop reports, processing counts + ops chips) and profile click-to-upload (`POST /auth/me/avatar`, no Avatar URL field) pass widget tests. Upload is self-only (no `user_id` on the client).

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Extra analytics tiles | A | `admin_home_screen_test.dart` S-095 | Pass |
| 2 | Tile destinations | A | same + ops nav keys | Pass |
| 3 | Ops chip row | A | `adminOpsNav` | Pass |
| 4 | Change photo + multipart | A | `profile_screen_test.dart` S-095 | Pass |
| 5 | Avatar URL field gone | A | `profile_screen_test.dart` | Pass |
| 6 | Account avatar photo or initials | A | `profile_screen_test.dart` / account shell | Pass |
| 7 | Cannot target another user | A | client calls `/auth/me/avatar` only | Pass |

**Coverage:** 7 / 7 AC mapped

---

## Backend tests

None (existing avatar endpoint).

---

## Mobile tests

### Added / updated
- `mobile/test/admin_home_screen_test.dart` S-095
- `mobile/test/profile_screen_test.dart` S-095

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested
- [x] AI disclaimer verified (if applicable)
- [x] Ready for PM acceptance
