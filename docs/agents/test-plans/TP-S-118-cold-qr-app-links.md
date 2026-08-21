# TP-S-118: Cold review QR App Links — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-118 |
| **Author** | Tester |
| **Date** | 2026-08-21 |

---

## Scope

Android App Links + mobile UUID/slug collect lookup. Web collect UI must not change. WhatsApp QR out of scope.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | Existing `GET /businesses/id/{id}` — no new pytest |
| Frontend | — | No collect UI tests; do not regress `CollectQrCard` |
| Mobile | flutter_test | UUID path, slug path, unknown id empty state |
| Integration | Manual | `adb` VIEW intent; camera scan only on HTTPS host after fingerprint |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated (route+lookup) + Manual (intent) | `collect_review_screen_test.dart` UUID path; M-001 |
| 2 | Manual / inspection | M-002 CollectQrCard / WhatsApp / collect page untouched |
| 3 | Automated | UUID `initialLocation` loads shop via `getById` |
| 4 | Automated | existing slug tests still pass |
| 5 | Automated | unknown id/slug empty state |
| 6 | Automated | `share_review_link_sheet_test.dart` still `{webBaseUrl}/collect/{slug}` |

After tests land, update `README.md` §11 Collect review row.

---

## RBAC test cases

Public collect view already ungated (S-059). No new auth endpoints.

---

## Manual checklist

- [ ] M-001: `adb shell am start -a android.intent.action.VIEW -d "https://frontend-production-ed77.up.railway.app/collect/<uuid>"` opens `CollectReviewScreen` when the matching APK is installed
- [ ] M-002: web dashboard still shows `{origin}/collect/{uuid}` and WhatsApp `wa.me`; collect wizard unchanged
- [ ] M-003: camera scan of `localhost` on a physical phone is **not** expected to open the app

---

## Environment

- `AI_PROVIDER=mock`
- Flutter widget tests only for cheap pack
