# TR-S-116: Home rail slider, browse invites, Shop back, Google button — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-116 |
| **Date** | 2026-08-21 |
| **Tester** | Builder (index-row) |
| **Verdict** | Ship |

---

## AC coverage

| AC | Criterion | Type | Evidence | Result |
|----|-----------|------|----------|--------|
| 1 | Web rail prev/next, peek, scrollbar not hidden; no invented stats | A | `SocialProofRail.test.tsx` — Previous/Next shops; no hidden scrollbar classes; no-digit test still Pass | Pass |
| 2 | Mobile rail prev/next keys; no invented stats on rail | A | `home_screen_test.dart` — `socialProofPrev` / `socialProofNext`; rail has no `12` or `%` | Pass |
| 3 | Invite cards, no SegmentedButton, lists hidden until tap | A | `home_screen_test.dart` — `S-116: category/neighborhood invites hide lists until tapped` | Pass |
| 4 | Invite then category/city tap → Explore query | A | AC8/AC9 in `home_screen_test.dart` | Pass |
| 5 | Shop hub system back → Home; nested pops hub first | A | `app_shell_test.dart` — two S-116 back tests | Pass |
| 6 | Google button filled + strong border + G mark; hide if unconfigured | A | `google_sign_in_button_test.dart`; `register_google_auth_test.dart` | Pass |

---

## Notes

- S-114 AC 2–3 segmented browse is superseded; tests no longer expect `browseModeToggle`.
- No API changes.
- Index-row runs: `npx jest src/components/home/__tests__/SocialProofRail.test.tsx`; `flutter test test/home_screen_test.dart test/app_shell_test.dart test/google_sign_in_button_test.dart test/register_google_auth_test.dart`.
