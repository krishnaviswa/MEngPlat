# TR-S-118: Cold review QR App Links — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-118 |
| **Author** | Tester |
| **Date** | 2026-08-21 |
| **Recommendation** | Ship |

---

## Summary

Mobile collect now resolves UUID or slug the same way as web. Android declares HTTPS App Links for `/collect` on the production frontend host. Web collect wizard, `CollectQrCard` payload, and WhatsApp `wa.me` QR were not changed. Camera→app on Android 12+ still needs a real SHA-256 in `assetlinks.json` (placeholder committed). `localhost` scans remain browser/fail-on-phone by design.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | App Links + UUID QR open Flutter collect | A + M | `collect_review_screen_test.dart::S-118 AC3`; AndroidManifest `pathPrefix=/collect`; M-001 | Pass (A); M-001 not run (no emulator here) |
| 2 | No app / unverified still web; collect UI + WhatsApp untouched | M | M-002 inspection: `CollectQrCard.tsx` still `{origin}/collect/{businessId}`; `WhatsAppUpdateCard` still `wa_url`; collect page not edited | Pass |
| 3 | UUID → `GET /businesses/id/{id}` | A | `business_collect_resolve_test.dart::resolveCollectTarget uses getById for a UUID`; collect screen UUID path | Pass |
| 4 | Slug → getBySlug; 404 falls back to id | A | existing slug collect tests; `resolveCollectTarget falls back to getById when slug returns 404` | Pass |
| 5 | Unknown id/slug empty state | A | `collect_review_screen_test.dart::S-118 AC5` | Pass |
| 6 | Share sheet still `{WEB_BASE_URL}/collect/{slug}`, not API host | A | `share_review_link_sheet_test.dart::AC1: shows a QR code encoding the business public web collection URL` | Pass |

**Coverage:** 6 / 6 AC mapped

---

## Backend tests

None (existing public GET).

---

## Frontend tests

None (collect UI frozen). Added static `frontend/public/.well-known/assetlinks.json` (fingerprint placeholder).

---

## Mobile tests

### Added
- `mobile/test/business_collect_resolve_test.dart`
- `mobile/test/collect_review_screen_test.dart` S-118 UUID + unknown-target cases

### Run output
```
cd mobile && flutter test test/collect_review_screen_test.dart test/business_collect_resolve_test.dart test/share_review_link_sheet_test.dart
All tests passed (14).

cd mobile && flutter analyze lib/features/businesses/business_repository.dart lib/features/businesses/business_list_provider.dart lib/features/reviews/collect_review_screen.dart test/collect_review_screen_test.dart test/business_collect_resolve_test.dart
No issues found.
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `adb` VIEW of production `/collect/{uuid}` | Not run (no Android SDK on this host) |
| M-002 | Web QR + WhatsApp + collect page unchanged | Pass (diff inspection) |
| M-003 | `localhost` camera scan does not open app | Pass by design (documented) |

---

## Regressions

Share-sheet tests still encode `AppConfig.webBaseUrl` + slug.

---

## Gaps / rework items

1. Replace `PASTE_SIDELOAD_OR_PLAY_APP_SIGNING_SHA256_COLON_SEPARATED` in `assetlinks.json` with the sideload/Play SHA-256 before expecting Android 12+ camera scans to skip the browser.
2. M-001 emulator/device intent check when an Android SDK is available.

---

## Sign-off

- [x] All AC mapped to tests
- [x] README §11 feature → test index updated
- [x] RBAC: no new endpoints; public collect view unchanged
- [x] AI disclaimer n/a
- [x] Ready for PM acceptance
