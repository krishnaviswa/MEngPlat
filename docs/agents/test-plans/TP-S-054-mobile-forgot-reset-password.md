# TP-S-054: Mobile forgot/reset password (M-65) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-054 |
| **Author** | Tester |
| **Date** | 2026-08-17 |

---

## Scope

Mobile-only, request-half-only forgot-password flow: a new `forgotPasswordLink` on
`login_screen.dart`, a new `ForgotPasswordScreen` (`/forgot-password`) that calls the
already-Accepted `POST /auth/forgot-password` (S-035) and shows a generic
confirm-or-error state, plus a router redirect carve-out so the unauthenticated route is
reachable. No in-app reset step (AC 5 is a scope decision, not a gap) and no backend
changes. Reuses the OpenAPI regen forced by this slice's own AC 7.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile widget | `flutter test` | Link visibility, screen contents, generic confirm/error copy, retry, back-to-sign-in, router carve-out |
| Backend | n/a | No new/changed endpoints — `/auth/forgot-password` unchanged since S-035 |
| Codegen (AC 7) | Code review + `flutter analyze` | `AuthRepository.forgotPassword` calls a generated method/model, not a hand-rolled `Dio.post` |
| Integration | Manual | Live-backend smoke test (widget tests fake `AuthController`, so they don't exercise the real generated HTTP client) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `forgot_password_screen_test.dart::AC1: forgotPasswordLink is visible on the login screen` |
| 2 | Automated | `forgot_password_screen_test.dart::AC2: tapping the link opens a screen with only an email field and submit button` |
| 3 | Automated | `forgot_password_screen_test.dart::AC3/AC5: submitting a well-formed email shows the generic confirmation...`; `::AC3: confirmation copy is identical for an unknown/unregistered-looking email (no enumeration)` |
| 4 | Automated | `forgot_password_screen_test.dart::AC4: network/5xx failure shows a generic error and allows retry; never silently succeeds` |
| 5 | Automated | `forgot_password_screen_test.dart::AC3/AC5: ...` (asserts `find.textContaining("phone's browser")`, no in-app token field) |
| 6 | Automated | `forgot_password_screen_test.dart::AC6: Back to sign in from the form state...`; `::AC6: Back to sign in from the confirmation state...` |
| 7 | Manual (code review) | M-001 — confirm `AuthRepository.forgotPassword` uses the generated `forgotPasswordApiV1AuthForgotPasswordPost` + `ForgotPasswordRequest`/`MessageResponse` types (not a raw `Dio` call); `flutter analyze` clean confirms the generated client actually exposes them |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| `POST /auth/forgot-password` | unauthenticated (all roles pre-auth) | Allowed — public endpoint, no role gating (unchanged from S-035); no negative RBAC case applies |

---

## Edge cases

- Unknown vs. known email produce byte-identical confirmation copy (no enumeration).
- Retry after a failed submit re-invokes the API rather than getting stuck in an error state.
- Already-authenticated user navigating to `/forgot-password` is out of scope per Architect (left reachable, not guarded) — not tested.
- Router carve-out: unauthenticated user is *not* bounced back to `/login` when navigating to `/forgot-password` (would otherwise silently break AC 1–6).

---

## Manual checklist (if applicable)

- [ ] M-001: Code review — `AuthRepository.forgotPassword` uses generated codegen types (AC 7).
- [ ] M-002: `docker compose up --build`; from a real device/emulator, submit a real email through `ForgotPasswordScreen` and confirm the generic 200 confirmation renders (widget tests fake `AuthController` above the repository layer, so no test here exercises the live Dio call end to end).

---

## Environment

- Widget tests only; `authControllerProvider` overridden with a fake `AuthController` (no live backend, no `AI_PROVIDER` relevance — this flow has no AI content).
