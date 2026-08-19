# TR-S-085: Profile avatar upload — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-085 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship — ACs 1–10 pass. README §7 / §8 / §12 documentation DoD is still open (not an AC failure; Architect/Builder before PM Accept). |

---

## Summary

**Pass** on all 10 acceptance criteria. I read the Builder’s implementation (`avatar_service.py`, `auth.py` `POST /me/avatar`, `Avatar.tsx`, `Navbar.tsx`, `ProfilePage.tsx`, `ClientLayout.tsx`, `api.ts`) against the Architect spec, then independently re-ran the backend and frontend suites for this slice.

**AC10 (no AI analysis) — independently re-verified, holds.** `avatar_service.py` imports only `User`, photo-validation constants, `upload_from_bytes`, and `get_storage_provider()`. An AST walk of that module asserts it never imports `app.services.ai` / `get_ai_provider`. At runtime, `POST /api/v1/auth/me/avatar` was exercised with spies on `app.services.ai.get_ai_provider`, `photo_service.get_ai_provider`, and `photo_service.save_business_photo` — none were called. The `UserResponse` body has no `ai_analysis` / `sentiment` fields. The UI surfaces (`Navbar`, `ProfilePage`, `Avatar`) carry no suggestion badge or AI disclaimer (the slice’s UX notes require the opposite of the usual AI-disclaimer rule).

**AC8 (own-user-only) — independently re-verified, cannot be bypassed via this endpoint.** Handler signature of `upload_my_avatar` has no `user_id`. OpenAPI for `POST /api/v1/auth/me/avatar` lists only multipart `file`. Extra `?user_id=` and form `user_id` of a second user still write the caller’s row; the victim’s `avatar_url` stays empty. Two independent uploads produce two distinct URLs. The client (`auth.uploadAvatar`) appends only `file`. No admin bypass exists on this route (`get_current_user` only). `PATCH /auth/me` still accepts `avatar_url` in `UserProfileUpdate` (pre-existing, own-user only) — that is not a cross-user write.

**Old-avatar cleanup on external URLs — actually covered.** `test_avatar_upload_replace_does_not_error_when_old_avatar_is_external_url` sets `avatar_url` to a Google `lh3.googleusercontent.com` URL in the DB, then hits the real HTTP endpoint with the real `LocalStorageProvider.delete()` (not mocked). Result: **200**, new stored URL, not the Google URL. `LocalStorageProvider.delete()` strips `/uploads/` and only unlinks if `path.exists()`, so an `https://…` URL is a no-op. Cleanup of a *storage-owned* previous file is covered separately by `test_avatar_upload_deletes_old_avatar_file_on_replace` (`delete` awaited once with the old URL).

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Navbar shows circular avatar image from `avatar_url`, still linking to `/profile` | A | `Navbar.test.tsx::"renders the user's avatar image when avatar_url is set"` | Pass |
| 2 | Navbar initials fallback when `avatar_url` is empty; `/profile` link unchanged. Also `Avatar` `onError` fallback | A | `Navbar.test.tsx::"renders an initials fallback when avatar_url is null"`; `Avatar.test.tsx::"renders initials fallback when avatar_url is unset"`; `Avatar.test.tsx::"falls back to initials when the image fails to load (onError)"` | Pass |
| 3 | `/profile` “Avatar URL” input gone; large clickable avatar with “Change photo” affordance | A | `ProfilePage.test.tsx::"no longer renders the Avatar URL text input"`; `ProfilePage.test.tsx::"opens the hidden file input when the avatar is clicked"` (asserts “Change photo”) | Pass |
| 4 | Click opens hidden file input restricted to image types | A | Same click test — `accept="image/jpeg,image/png,image/webp,image/gif"` and `input.click()` | Pass |
| 5 | Successful upload applies immediately on `/profile` and Navbar without “Save changes”; `updateMe` does not send `avatar_url` | A | `ProfilePage.test.tsx::"uploads a selected avatar and shows it immediately on success"` (`updateMe` not called; `mh:user-updated` dispatched); `ProfilePage.test.tsx::"persists edited phone/address…"` (payload has no `avatar_url`); `ClientLayout.test.tsx::"updates the Navbar avatar when mh:user-updated fires"` | Pass |
| 6 | Too large / wrong type → 400, inline error, previous avatar retained | A | Backend: `test_avatar_upload_oversized_file_rejected_and_previous_unchanged`; `test_avatar_upload_disallowed_content_type_rejected`. Frontend: `ProfilePage.test.tsx::"shows an inline error and retains the previous avatar when the upload fails"`; `"retains a previous photo when a replacement upload is rejected"` | Pass |
| 7 | Visible pending state while upload in flight | A | `ProfilePage.test.tsx::"shows an uploading state on the avatar while the request is in flight"` (`Uploading…`, button disabled) | Pass |
| 8 | Own-user only; no way to set another user’s avatar | A | `test_avatar_upload_cannot_target_another_user`; `test_avatar_upload_ignores_foreign_user_id_query_and_form` (signature + OpenAPI + extra `user_id` ignored); parametrized `test_avatar_upload_succeeds_and_updates_avatar_url` for customer/merchant/admin | Pass |
| 9 | Signed-out visitor: no avatar-upload affordance | A | `Navbar.test.tsx::"renders no avatar for a signed-out visitor"` (no file input / Change-photo button; Login shown); `ProfilePage.test.tsx::"redirects to /login and does not render the form when there is no stored token"` | Pass |
| 10 | Avatar not run through `analyze_image()`; no AI badge/disclaimer in UI | A | `test_avatar_upload_does_not_invoke_ai_image_analysis`; `ProfilePage.test.tsx::"does not show an AI suggestion badge or disclaimer on the avatar"`; `Navbar.test.tsx::"does not attach an AI suggestion badge to the nav avatar"` | Pass |

**Coverage:** 10 / 10 AC mapped (all automated).

---

## Backend tests

### Added / extended (`backend/tests/test_avatar.py`)
- `test_avatar_upload_succeeds_and_updates_avatar_url` (customer / merchant / admin)
- `test_avatar_upload_oversized_file_rejected_and_previous_unchanged`
- `test_avatar_upload_disallowed_content_type_rejected`
- `test_avatar_upload_unauthenticated_rejected` (401)
- `test_avatar_upload_deletes_old_avatar_file_on_replace`
- `test_avatar_upload_replace_does_not_error_when_old_avatar_is_external_url` (Google picture URL → 200)
- `test_avatar_upload_cannot_target_another_user`
- `test_avatar_upload_ignores_foreign_user_id_query_and_form` (AC8 bypass attempt)
- `test_avatar_upload_does_not_invoke_ai_image_analysis` (AC10)

### Run output (independently re-run)
```
# Each case in a fresh process (see note below)
python -m pytest tests/test_avatar.py::… -q
11 passed (all cases in test_avatar.py)
```

**Local pytest note:** `python -m pytest tests/test_avatar.py` as a *single* process fails after the first case with asyncpg `another operation is in progress` / `Event loop is closed`. The same cascade hits *unrelated* `tests/test_photos.py` (1st case pass, rest fail). This is the known function-scoped asyncio loop vs module-level `create_async_engine` pool issue, not an S-085 defect. Isolated processes: **11/11 avatar cases pass**.

**`upload_from_bytes` rename:** `photo_service.py` exposes `upload_from_bytes` (no underscore); `save_business_photo()` still calls it. `test_photo_upload_by_owning_merchant_succeeds` passed in isolation — owning-merchant gallery upload still works after the rename.

---

## Frontend tests

### `frontend/src/components/ui/__tests__/Avatar.test.tsx`
- `"renders an image when avatar_url is set"`
- `"renders initials fallback when avatar_url is unset"`
- `"renders a single-letter fallback for a one-word name"`
- `"falls back to initials when the image fails to load (onError)"`

### `frontend/src/components/__tests__/Navbar.test.tsx`
- `"renders the user's avatar image when avatar_url is set"`
- `"renders an initials fallback when avatar_url is null"`
- `"renders no avatar for a signed-out visitor"`
- `"does not attach an AI suggestion badge to the nav avatar"`

### `frontend/src/components/__tests__/ProfilePage.test.tsx` (S-085 cases)
- `"no longer renders the Avatar URL text input"`
- `"opens the hidden file input when the avatar is clicked"`
- `"uploads a selected avatar and shows it immediately on success"`
- `"shows an inline error and retains the previous avatar when the upload fails"`
- `"retains a previous photo when a replacement upload is rejected"`
- `"shows an uploading state on the avatar while the request is in flight"`
- `"does not show an AI suggestion badge or disclaimer on the avatar"`
- plus existing S-019 case asserting `updateMe` payload has no `avatar_url`

### `frontend/src/app/__tests__/ClientLayout.test.tsx`
- `"updates the Navbar avatar when mh:user-updated fires"`

### Run output (independently re-run)
```
cd frontend && npx jest src/components/__tests__/ProfilePage.test.tsx src/components/__tests__/Navbar.test.tsx src/components/ui/__tests__/Avatar.test.tsx src/app/__tests__/ClientLayout.test.tsx --silent
Test Suites: 4 passed, 4 total
Tests:       22 passed, 22 total
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Swagger `/docs` includes `POST /api/v1/auth/me/avatar` with multipart `file` only | Pass (OpenAPI asserted in `test_avatar_upload_ignores_foreign_user_id_query_and_form`) |
| M-002 | docker compose smoke of click-to-upload in a real browser | Not run this session (RTL + API coverage sufficient for AC) |

---

## Regressions

- Photo-gallery helper rename (`_upload_from_bytes` → `upload_from_bytes`) does not change `save_business_photo()` behavior (source + isolated owning-merchant photo test).
- `PATCH /auth/me` still *can* set `avatar_url` at the API layer (`UserProfileUpdate.avatar_url` unchanged per Architect). The profile form no longer submits it. Not an AC8 bypass (still own user).

---

## Gaps / rework items

1. **README §7** — `POST /auth/me/avatar` is not in the Authentication table (PM DoD / Architect checklist). Assign Architect/Builder.
2. **README §8** — `Avatar` primitive is not listed; `Navbar.tsx` row still says auth/role links only.
3. **README §12** — no parity row for click-to-upload profile photo. M-48 is still “Profile edit” / S-029 `implemented`; mobile is unlikely to have this upload flow yet → should be a new `unimplemented` (or M-48 notes `partial`).

None of these fail AC 1–10.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (401 unauthenticated; all three roles can upload own avatar; extra `user_id` cannot retarget)
- [x] AI disclaimer verified **not** present on avatar surfaces (AC10 by design)
- [ ] Ready for PM acceptance — after README §7 / §8 / §12 updates

**Handoff:** ACs pass → PM may Accept once documentation DoD is filled. No Builder functional rework.
