# TP-S-085: Profile avatar upload — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-085 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Click-to-upload own profile photo: `POST /api/v1/auth/me/avatar`, Navbar avatar/initials, `/profile` file picker independent of Save changes. No AI analysis. No cross-user write.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Happy path all roles, 400 type/size, 401, own-user-only, no AI, old-file cleanup |
| Frontend | RTL | `Avatar`, `Navbar`, `ProfilePage`, `ClientLayout` `mh:user-updated` |
| Integration | OpenAPI in pytest; optional docker browser smoke |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `Navbar.test.tsx` — image from `avatar_url`, link `/profile` |
| 2 | Automated | Navbar initials; `Avatar.test.tsx` unset + `onError` |
| 3 | Automated | `ProfilePage.test.tsx` — no Avatar URL input; Change photo |
| 4 | Automated | Same click test — hidden file input `accept` image types |
| 5 | Automated | Immediate apply; `updateMe` has no `avatar_url`; `ClientLayout` event |
| 6 | Automated | pytest oversized/wrong type; ProfilePage inline error, previous retained |
| 7 | Automated | ProfilePage uploading overlay while in flight |
| 8 | Automated | pytest customer/merchant/admin; extra `user_id` ignored |
| 9 | Automated | Navbar signed-out; ProfilePage no token → `/login` |
| 10 | Automated | pytest no `get_ai_provider`; UI no suggestion copy |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated POST | none | 401 |
| Own upload | customer, merchant, admin | 200, own `avatar_url` |
| Extra `user_id` query/form | any authenticated | still writes caller only |
| Admin setting another user | admin | not possible (no param) |

---

## Edge cases

- Old `avatar_url` is an external Google picture URL — replace must 200 (storage delete no-op).
- `upload_from_bytes` rename must not break owning-merchant gallery upload.

---

## Manual checklist

- [x] M-001: OpenAPI lists `POST /api/v1/auth/me/avatar` with multipart `file` only (covered in `test_avatar_upload_ignores_foreign_user_id_query_and_form`)
- [ ] M-002: docker compose click-to-upload in a real browser (optional; RTL + API cover ACs)

---

## Environment

- `AI_PROVIDER=mock`
- Isolated pytest process recommended locally (shared Postgres / event-loop note in TR-S-085)
