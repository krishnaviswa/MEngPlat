# TP-S-055: Mobile phone OTP sign-in (M-74) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-055 |
| **Author** | Tester |
| **Date** | 2026-08-17 |

---

## Scope

Mobile-only `PhoneOtpPanel` embedded in both `login_screen.dart` and
`register_screen.dart`, calling the already-Accepted `POST /auth/phone/request` and
`POST /auth/phone/verify` (S-044 / ADR-011). Covers the number → send-code → code →
verify state machine, the login-omits-fullName/role vs. register-supplies-them
asymmetry, TOTP-skip on success, and `postLoginPath` routing. No backend changes.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile widget (panel-level) | `flutter test` | Panel UI, country code, disabled-state gating, generic send confirmation, verify success/error paths, login vs. register asymmetry |
| Mobile widget (router-level) | `flutter test` | End-to-end sign-in through the real `routerProvider`, asserting `postLoginPath` lands on the correct tab per role |
| Codegen (AC 8) | Code review + `flutter analyze` | `AuthRepository.requestPhoneOtp`/`verifyPhoneOtp` call generated methods/models, not hand-rolled `Dio` calls |
| Integration | Manual | Live-backend smoke test (widget tests fake `AuthController`, bypassing the real generated HTTP client) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `phone_otp_panel_test.dart::AC1: shows country code selector (+91 default), number field, and Send SMS code button`; `::AC1: panel is present below the credentials fields` (LoginScreen group) |
| 2 | Automated | `phone_otp_panel_test.dart::AC2: panel is present in the equivalent position on the register screen` (RegisterScreen group) |
| 3 | Automated | `phone_otp_panel_test.dart::AC3: sending a code always shows the generic confirmation flow and reveals code field + verify button` |
| 4 | Automated | `phone_otp_panel_test.dart::AC4: verify from register sends the in-progress full_name and role, updated live as name changes`; `::AC4: on success the user is signed in (JWT/session state set), TOTP step skipped`; `phone_otp_router_redirect_test.dart::AC4: phone sign-in from login (customer, default role) lands on Explore...`; `::AC4: phone sign-in from register (merchant role) lands on the merchant home...` |
| 5 | Automated | `phone_otp_panel_test.dart::AC5: verifying a brand-new number from login omits full_name and surfaces the backend 400 as-is` |
| 6 | Automated | `phone_otp_panel_test.dart::AC6: invalid/expired code (401) shows a plain error and the code field remains editable for retry` |
| 7 | Automated (existing regression) | `register_google_auth_test.dart::AC2/AC3: merchant register is offered; admin is not` — pre-existing test proving admin is absent from the register role dropdown; this slice does not touch that dropdown, so the 403-blocked path stays UI-unreachable as before |
| 8 | Manual (code review) | M-001 — confirm `AuthRepository.requestPhoneOtp`/`verifyPhoneOtp` use the generated `phoneOtpRequestApiV1AuthPhoneRequestPost`/`phoneOtpVerifyApiV1AuthPhoneVerifyPost` + `PhoneOtpRequest`/`PhoneOtpVerifyRequest` types; `flutter analyze` clean confirms the generated client exposes them |

---

## RBAC test cases

| Case | Role (target) | Expected |
|------|----------------|----------|
| `POST /auth/phone/request` | any (pre-auth) | Allowed — no role in request body |
| `POST /auth/phone/verify`, existing phone | any | Allowed — logs in as stored role, request `role` ignored |
| `POST /auth/phone/verify`, brand-new phone, `role` omitted (login) | defaults customer | Allowed |
| `POST /auth/phone/verify`, brand-new phone, `role=merchant` (register) | merchant | Allowed |
| `POST /auth/phone/verify`, brand-new phone, `role=admin` | admin | Blocked (403) — UI-unreachable, covered indirectly via AC 7 |

---

## Edge cases

- Country code switch (`+91` → `+1`) concatenates correctly into the single `phone` field sent to the backend.
- "Send SMS code" / "Verify and sign in" buttons are disabled until their respective inputs are non-empty / ≥4 chars.
- Live-edited `fullName`/role on the register screen (typed, then changed, then role switched) are picked up fresh at verify time, not stale at panel-build time.
- 401 leaves the code field editable and pre-filled for a retry (not cleared).

---

## Manual checklist (if applicable)

- [ ] M-001: Code review — `AuthRepository.requestPhoneOtp`/`verifyPhoneOtp` use generated codegen types (AC 8).
- [ ] M-002: `docker compose up --build`; real device/emulator, send + verify a real (mock-SMS-provider) code through both login and register panels.

---

## Environment

- `authControllerProvider` overridden with a fake `AuthController` in all widget tests (no live backend). Router-level tests (`phone_otp_router_redirect_test.dart`) also fake `BusinessRepository`/`NotificationsRepository`/`FavoritesRepository` so the post-login shell renders without network calls.
