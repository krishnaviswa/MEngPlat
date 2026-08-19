# Slice: S-085 — Profile avatar upload (Facebook-style click-to-upload)

| Field | Value |
|-------|-------|
| **Slice ID** | S-085 |
| **Phase** | 2 Core |
| **Status** | Specified |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** signed-in user (customer, merchant, or admin)
**I want** to see my profile photo in the site header and change it by clicking my avatar and picking an image file — instead of typing a raw image URL into a text box
**So that** I have a recognizable identity across the site, and updating my photo feels as easy and immediate as it does on Facebook

---

## Background

Confirmed by reading `backend/app/models/__init__.py`: `User.avatar_url` (`String(512)`,
nullable) already exists on the user record. Confirmed by reading
`frontend/src/components/ProfilePage.tsx`: today the only way to set it is a plain "Avatar
URL" text `Input` (id `avatar_url`) that the user must manually paste a URL into, batched
with every other profile field behind the page's single "Save changes" submit
(`auth.updateMe(...)`). Confirmed by reading `frontend/src/components/Navbar.tsx`: the
signed-in user's identity in the top-right nav area is rendered as plain text only
(`{user.full_name}`, linking to `/profile`) — no `<img>`, no avatar, anywhere in the
header, even though `avatar_url` is already available on the `User` object passed into
`Navbar`.

Confirmed by reading `backend/app/routers/photos.py`: the existing
`POST /api/v1/photos/upload` endpoint is not reusable as-is for this — its `Photo` model
is tied to `business_id`/`review_id`, and it triggers AI image analysis via
`get_ai_provider().analyze_image()`. Neither applies to a personal profile photo. A
personal avatar is not business content and must not be run through the AI image-analysis
pipeline or carry any AI badge/insight.

This slice replaces the manual URL-paste flow with direct upload: a visible avatar in the
nav's existing right-aligned user area, and a large clickable avatar on `/profile` that
opens a file picker and applies the new photo immediately on selection — independent of
the page's separate "Save changes" button, matching the confirmed Facebook-style pattern.

---

## Acceptance criteria

1. **Given** a signed-in user whose `avatar_url` is set, **when** any page with the global `Navbar` renders, **then** the nav's user area (still linking to `/profile`, as today) shows a small circular avatar image loaded from `avatar_url` instead of (or alongside, at minimum replacing the plain-text-only presentation) the user's name as bare text.
2. **Given** a signed-in user whose `avatar_url` is `null`/empty, **when** the `Navbar` renders, **then** it shows a fallback avatar built from the user's initials (derived from `full_name`) instead of a broken image or blank space — the link to `/profile` still works unchanged.
3. **Given** a signed-in user on `/profile`, **when** the page renders, **then** the current "Avatar URL" text input is gone, replaced by a large avatar (photo if `avatar_url` is set, else the same initials fallback as AC2) that visibly indicates it's clickable (e.g. hover overlay with a camera icon / "Change photo" affordance).
4. **Given** the large avatar on `/profile`, **when** the user clicks it, **then** a native file picker opens (via a hidden file input) restricted to image types.
5. **Given** the user selects a valid image file (allowed content-type and size, per the existing `ALLOWED_CONTENT_TYPES`/`MAX_UPLOAD_BYTES` rules), **when** the upload completes, **then** the new avatar is applied and visible immediately on the `/profile` page **and** reflected in the `Navbar`, without the user needing to click the page's separate "Save changes" button and without that button's save covering/re-submitting the avatar field.
6. **Given** the user selects a file that is too large or has a disallowed content-type, **when** the upload is attempted, **then** the request is rejected, a clear inline error message is shown near the avatar (not a silent failure), and the user's previous avatar (image or initials fallback) remains displayed unchanged.
7. **Given** an upload is in progress, **when** the user is looking at the avatar, **then** there is a visible loading/pending state on the avatar (Builder's choice of exact treatment) so the click registered and something is happening.
8. **Given** any signed-in user regardless of role (customer, merchant, or admin), **when** they use this upload flow, **then** it updates only their own `avatar_url` — there is no way, via this endpoint or the UI, to set or change another user's avatar.
9. **Given** a signed-out (unauthenticated) visitor, **when** they view any page, **then** no avatar-upload affordance is shown (there's no profile to click into — this simply follows the existing `/profile` auth gate, unchanged).
10. **Given** the newly uploaded avatar image, **when** it is stored and served, **then** it is not run through `get_ai_provider().analyze_image()` and carries no AI-suggestion badge or disclaimer anywhere in the UI — it is plain personal profile data, not AI-analyzed business content.

---

## UX notes

- **Screens / routes:** global `Navbar` (every page); `/profile` (`ProfilePage.tsx`).
- **Components to reuse:** existing `Card`, `Input`, `Button` primitives on `/profile`; a
  new small presentational **Avatar** component (image-or-initials) is expected, reused in
  both `Navbar` and `ProfilePage` rather than duplicating the fallback logic in two places
  — exact component boundary is a Builder/Architect call.
- **Empty states / errors:** no-avatar → initials fallback (AC2, AC3); invalid file
  (too large / wrong type) → inline error near the avatar, previous avatar retained (AC6).
- **AI disclaimer required?** No. This is explicitly **not** AI-analyzed content (AC10) —
  no "suggestion" language, no AI badge on the avatar anywhere.

---

## Out of scope

- **Image cropping/editing UI.** The uploaded file is applied as-is; no crop/zoom/rotate
  step before it's saved.
- **Avatar moderation or AI analysis of the uploaded image.** Deliberately not wanted —
  this is a personal photo, not business content, and should not go through
  `analyze_image()` or produce any AI insight/badge (see AC10).
- **Removing/deleting an avatar back to blank** (reverting to the initials fallback after
  one has been uploaded). Not asked for — this slice only covers *replacing* the avatar by
  uploading a new one; a "remove photo" action can be a future slice if wanted.
- **Uploading or viewing avatars for anyone other than the signed-in user** (e.g. an admin
  setting another user's avatar, or avatars appearing on `ReviewCard`/`BusinessCard`
  outside the nav/profile surfaces named here) — not part of this slice.

---

## Dependencies

- None blocking at the product level — this is a self-contained addition to the existing
  `User.avatar_url` field, `Navbar`, and `ProfilePage`.
- **Soft note for Architect:** shares the storage abstraction (`get_storage_provider()`)
  and validation constants (`ALLOWED_CONTENT_TYPES`, `MAX_UPLOAD_BYTES` in
  `backend/app/services/photo_service.py`) with the existing business/review photo-upload
  path (`backend/app/routers/photos.py`), but must not reuse that endpoint's `Photo`
  model or its AI-analysis trigger — see Background.

---

## Definition of done (PM)

- [ ] All AC verified in test report
- [ ] UX matches notes above
- [ ] Documented in `README.md` §7 API reference (new avatar upload endpoint) / §8
      Frontend guide (new `Avatar` component pattern)
- [ ] `README.md` §12 Web ↔ mobile feature parity tracker row added for this capability
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

### New endpoint (backend)

A new route on the **existing** `auth` router (`backend/app/routers/auth.py`), sitting
next to `GET /me` and `PATCH /me` — not a new router module, since this is still
"operate on the caller's own account," just via `multipart/form-data` instead of JSON.
Business logic (validation, storage save, old-file cleanup) goes in a **new**
`backend/app/services/avatar_service.py` (thin router, per `backend/CLAUDE.md`) — it must
not live in `photo_service.py`, since it does not touch the `Photo`/`AIAnalysis` models
or `get_ai_provider()` at all (AC10).

`photo_service.py`'s `_upload_from_bytes()` helper (wraps raw bytes as an `UploadFile` so
`get_storage_provider().save()` can be called without a real multipart file object) is
reused as-is from `avatar_service.py` rather than duplicated. Since it is now shared
across two service modules, rename it `upload_from_bytes` (drop the leading underscore)
in `photo_service.py` and update its one existing call site — a one-line, low-risk
rename that turns an accidental private helper into a declared shared one; no behavior
change.

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| `POST` | `/api/v1/auth/me/avatar` | Bearer JWT (`get_current_user`) — any authenticated role | `multipart/form-data`: `file` (image; content-type/size validated against the existing `ALLOWED_CONTENT_TYPES` / `MAX_UPLOAD_BYTES` in `photo_service.py` — no new constants) | `200 OK` `UserResponse` (the full updated user, `avatar_url` set to the new file's URL) — same shape as `GET /auth/me` / `PATCH /auth/me`, so the frontend can reuse its existing `applyUser(User)` pattern unchanged |

**Errors:** `400` unsupported content-type or file too large (same copy as
`photo_service.py`'s existing 400s: `"Unsupported file type '<type>'. Allowed: ..."` /
`"File too large. Max size is 5MB."`); `401` not authenticated / inactive (standard
`get_current_user` behavior, unchanged).

No `user_id` path or body param anywhere in the contract — the target user is always
`current_user` from `get_current_user`, which is what makes AC8 (own-user-only)
structurally true rather than a manually-checked rule.

Deliberately **not** reusing `POST /api/v1/photos/upload`: that endpoint requires
`business_id` or `review_id` (neither applies to a personal avatar), writes a `Photo`
row, and unconditionally calls `get_ai_provider().analyze_image()` — all three are wrong
for a personal profile photo (AC10, and see slice Background).

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Upload/replace own avatar (`POST /auth/me/avatar`) | yes | yes | yes |
| Upload/replace another user's avatar | no (not possible — no `user_id` param exists; endpoint always targets `get_current_user`) | no (same) | no (same — admins do not get a bypass; out of scope per slice, AC8) |
| View own avatar (Navbar / `/profile`) | yes | yes | yes |
| Avatar routed through AI image analysis / carries AI badge | no (never, for any role — AC10) | no | no |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** None. Confirmed by reading `backend/app/models/__init__.py`:
`User.avatar_url` (`String(512)`, nullable) already exists and is exactly the field this
endpoint writes — no migration, no new column, no new table. `UserResponse` and
`UserProfileUpdate` (`backend/app/schemas/__init__.py`) already expose `avatar_url`; no
schema changes needed for the response (the new endpoint reuses `UserResponse` as-is).

### Cache / side effects

- **`search:*` (Redis):** no invalidation needed. That cache holds business
  search/listing results (`backend/app/routers/search.py`, `businesses.py`), which do not
  embed a user's `avatar_url` anywhere in their payload shape. The one schema that *does*
  embed `avatar_url` on a nested user (`ReviewResponse.author: UserResponse | None`, in
  `schemas/__init__.py`) is served by `reviews.py`'s `GET` endpoints, which have no
  `cache_get`/`cache_set` calls at all (read live from the DB each request) — so a
  changed avatar is reflected immediately with nothing to invalidate.
- **Old avatar file cleanup (storage side effect):** on replace, the previous
  `avatar_url`'s underlying file is deleted from the storage backend, best-effort (see
  Risks/tradeoffs for why this is safe to do unconditionally, including when the old URL
  is an external Google profile picture or a pre-existing manually-pasted URL, neither of
  which this endpoint owns).
- No AI provider is invoked (confirms AC10 at the design level, not just "the frontend
  shows no badge" — `avatar_service.py` never imports `app.services.ai`).

### Frontend

- **Route:** no new route. Two existing surfaces change:
  - Global `Navbar` (`frontend/src/components/Navbar.tsx`), rendered from
    `frontend/src/app/ClientLayout.tsx` on every page.
  - `/profile` (`frontend/src/app/profile/page.tsx` → `ProfilePage.tsx`).
- **Rendering:** CSR for both. `Navbar` is already part of `ClientLayout.tsx`'s
  `"use client"` tree (no rendering-mode change); `ProfilePage.tsx` is already
  `"use client"`. No SSR involved anywhere in this slice.
- **Components:**
  - **New `Avatar` presentational component** — `frontend/src/components/ui/Avatar.tsx`
    (alongside `Button`, `Card`, `Input`, `Select`, since it's a reusable UI primitive,
    not screen-specific). Props: `{ user: Pick<User, "full_name" | "avatar_url">; size?:
    "sm" | "lg"; className?: string }`. Renders an `<img src={user.avatar_url}>` when set
    (with an `onError` fallback to the initials view, covering broken/unreachable URLs,
    not just `null`), else initials derived from `full_name` (first letter of the first
    two words, uppercase) on a colored circular background. Purely presentational — no
    click handling, no upload logic — so both call sites below wrap it themselves:
    - `Navbar.tsx`: replaces the bare-text `{user.full_name}` link with `<a
      href="/profile"><Avatar user={user} size="sm" />...</a>` (AC1/AC2). The existing
      `<a href="/profile">` wrapper is unchanged, just now renders `Avatar` instead of
      (or alongside, per AC1's "at minimum replacing") plain text.
    - `ProfilePage.tsx`: replaces the "Avatar URL" `Input` block (id `avatar_url`,
      currently lines ~158–169) with a large `Avatar` wrapped in a `<button
      type="button">` (not inside the profile `<form>`'s submit path, so it can never be
      swallowed by the "Save changes" submit — AC5) that opens a hidden `<input
      type="file" accept="image/jpeg,image/png,image/webp,image/gif" hidden>` on click
      (AC4), shows a hover overlay (camera icon / "Change photo") per the UX notes (AC3),
      and a pending/disabled visual state while the upload request is in flight (AC7).
      The now-unused `avatarUrl`/`setAvatarUrl` state and its `avatar_url` field in the
      `auth.updateMe(...)` submit payload are removed from `ProfilePage.tsx` accordingly.
  - **`frontend/src/lib/api.ts`:** add `uploadAvatar` to the existing `auth` client
    object, following `photos.upload()`'s multipart pattern exactly:
    ```ts
    uploadAvatar: (file: File) => {
      const form = new FormData();
      form.append("file", file);
      return apiFetch<User>("/api/v1/auth/me/avatar", { method: "POST", body: form });
    },
    ```
    `apiFetch` already special-cases `FormData` bodies (skips the JSON
    `Content-Type` header), so no other client changes are needed.
  - **Navbar ↔ `/profile` sync (AC5's "reflected in the Navbar... immediately"):**
    `ClientLayout.tsx` and `ProfilePage.tsx` each independently call `auth.me()` into
    their own local `useState<User | null>` — there is no shared store today, so a save
    on one does not by itself update the other (this is a pre-existing property of the
    app, not introduced here). To satisfy AC5 without a broader state-management
    refactor (out of proportion for this slice), add one small, additive mechanism:
    after a successful `auth.uploadAvatar()` response, `ProfilePage.tsx` dispatches a
    `window.dispatchEvent(new CustomEvent("mh:user-updated", { detail: updatedUser }))`;
    `ClientLayout.tsx` adds a matching `window.addEventListener("mh:user-updated", (e) =>
    setUser(e.detail))` next to its existing `pageshow` listener. This is scoped strictly
    to the avatar flow (the existing "Save changes" `auth.updateMe()` path is untouched,
    per the instruction not to touch unrelated behavior) and needs no new context
    provider, global store, or prop drilling.
  - Reused as-is: `Card`, `Input`, `Button` primitives already on `/profile` for every
    other field.

### Flow

```mermaid
sequenceDiagram
    participant User
    participant Profile as ProfilePage
    participant API as POST /auth/me/avatar
    participant Storage as get_storage_provider()
    participant Nav as Navbar (via ClientLayout)

    User->>Profile: clicks large avatar
    Profile->>User: opens hidden file input (AC4)
    User->>Profile: selects image file
    Profile->>Profile: shows pending state on avatar (AC7)
    Profile->>API: POST multipart file (Bearer token)
    alt valid content-type & size
        API->>API: current_user = get_current_user (own-user only, AC8)
        API->>Storage: save(file, "avatars/{user.id}")
        Storage-->>API: new_url
        API->>API: old_url = user.avatar_url; user.avatar_url = new_url; db.flush()
        API->>Storage: delete(old_url) best-effort, if old_url and old_url != new_url
        API-->>Profile: 200 UserResponse (new avatar_url)
        Profile->>Profile: applyUser(updated) -> avatar shown immediately (AC5)
        Profile->>Nav: window CustomEvent "mh:user-updated" (detail: updated user)
        Nav->>Nav: setUser(updated) -> nav avatar updates immediately (AC5)
    else invalid type / too large
        API-->>Profile: 400 {detail}
        Profile->>Profile: inline error shown, previous avatar retained (AC6)
    end
```

### Architect checklist

- [x] API contract defined — `POST /api/v1/auth/me/avatar`, matches `README.md` §7 API
      reference style (method/path/auth/request/response/errors); one new endpoint, no
      changes to any existing endpoint's contract.
- [x] RBAC matrix complete — all three roles identical (own-avatar-only; no role gets a
      cross-user bypass).
- [x] Data model impact documented — none; reuses existing `User.avatar_url` verbatim, no
      migration.
- [x] Cache invalidation considered — none required (`search:*` doesn't embed
      `avatar_url`; `ReviewResponse.author` isn't cached); old-file storage cleanup
      documented as a side effect, not a cache concern.
- [x] Uses AI/storage abstractions where applicable — `get_storage_provider()` reused
      exactly as `photos.py`/`photo_service.py` already use it; `get_ai_provider()`
      deliberately **not** called anywhere in this path (AC10).
- [x] ERD/API/FLOWS updates noted — no ERD change (no new table/column). When the Builder
      lands this, `README.md` §7 API reference needs the new endpoint row, and §8
      Frontend guide should note the new `Avatar` component pattern (per the slice's own
      Definition of done) — Architect will do this update once implementation lands, per
      `CLAUDE.md`'s handoff rule, not now.
- [x] No secrets in design.

### Risks / tradeoffs

- **Old avatar file: delete, not orphan — but best-effort and unconditional.** On
  replace, `avatar_service.py` calls `storage.delete(old_url)` whenever `old_url` is set
  and differs from the new URL, wrapped in `try/except` so a cleanup failure never blocks
  the avatar update itself. This is deliberately **not** gated on "does this URL look
  like one our storage provider produced" (e.g. it will also be called when `old_url` is
  a Google-provided `identity.picture` URL from `POST /auth/google`, or a pre-existing
  manually-pasted URL from before this slice replaced the text input) — a narrower guard
  was considered and rejected as unnecessary complexity, because both storage
  implementations are safe no-ops on a URL they don't own:
  `LocalStorageProvider.delete()` strips the `/uploads/` prefix and only unlinks if
  `path.exists()` (an external `https://...` URL will not exist under `base_path`, so
  it's silently skipped); `S3StorageProvider.delete()` strips the bucket's public base
  URL and calls `delete_object` with whatever remains as the key — a `delete_object` call
  for a non-existent key is itself a no-op in S3, not an error. Net effect: real
  self-uploaded avatars get cleaned up (no orphan growth in storage from repeated
  replaces), and external/legacy URLs are safely left untouched. Flagging so the Tester
  specifically verifies the "previous avatar was a Google picture URL, then user uploads
  a real file" case doesn't throw.
- **New router endpoint vs. a dedicated router module.** Chose to add `POST
  /auth/me/avatar` onto the existing `auth.py` router (next to `GET/PATCH /me`) rather
  than a new `avatars.py` router, since the resource being mutated is squarely "the
  caller's own account," matching every other `/me` route already there. Business logic
  still goes in a new `avatar_service.py` (not inline in the router, not bolted onto
  `photo_service.py`) to keep the "no `Photo` row, no AI analysis" boundary explicit at
  the module level, not just enforced by omission inside a shared function. No ADR
  warranted — this is a routing/module-boundary call, not a new integration, schema
  pattern, or auth change.
- **Cross-component sync via a `window` `CustomEvent`.** Chosen over introducing a
  React Context/global user store because the latter would touch every consumer of
  `auth.me()`-derived user state across the app for a one-field, one-screen-pair need —
  disproportionate for this slice. Tradeoff: this pattern is easy to forget to reuse if a
  *third* place ever needs live user-state sync (e.g. a future `full_name` edit
  reflecting in `Navbar` without reload); if that need shows up again, it's a signal to
  revisit with a proper shared store rather than a second bespoke event.
- **`_upload_from_bytes` → `upload_from_bytes` rename in `photo_service.py`.** Small,
  mechanical, single call-site-affecting rename to make an already-existing helper
  legitimately shared rather than importing another module's "private" (underscore-
  prefixed) symbol. Flagging only because it's a touch outside `avatar_service.py`
  itself — the one existing call site is inside `save_business_photo()` (the
  business-gallery upload path, `photo_service.py` lines ~30–90, used by `photos.py`'s
  `business_id` branch); Tester should confirm that path still passes unchanged after
  the rename (photos.py's separate review-attachment branch builds its `UploadFile`
  inline from the real request and does not call this helper at all, so it's
  unaffected).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-085-profile-avatar-upload.md`
- Test report: `docs/agents/test-reports/TR-S-085-profile-avatar-upload.md`
- ADR: TBD — a new authenticated upload endpoint separate from `photos.py` may warrant a
  short ADR if the Architect decides it needs its own router/service module; not
  prescribed here.

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created slice from a planning conversation confirming Facebook-style avatar upload. Confirmed by reading `backend/app/models/__init__.py`, `frontend/src/components/ProfilePage.tsx`, `frontend/src/components/Navbar.tsx`, and `backend/app/routers/photos.py` that `User.avatar_url` already exists but is only settable via a manual URL-paste text input, the nav shows no avatar image at all, and the existing photo-upload endpoint is unsuitable (business/review-scoped, triggers AI analysis). 10 numbered AC covering nav avatar/initials fallback, profile click-to-upload, immediate apply independent of "Save changes," reject-oversized/wrong-type with previous avatar retained, own-user-only scope, and explicit no-AI-analysis requirement. Out of scope: cropping, moderation/AI analysis, avatar removal. Status: Draft — handing off to Architect to fill the technical specification. |
| 2026-08-19 | Architect | Filled technical specification. New `POST /api/v1/auth/me/avatar` on the existing `auth.py` router (multipart `file` → `UserResponse`, own-user-only via `get_current_user`, no `user_id` param); logic in a new `backend/app/services/avatar_service.py` (thin router per layering rules) reusing `photo_service.py`'s `ALLOWED_CONTENT_TYPES`/`MAX_UPLOAD_BYTES` and `get_storage_provider()`, never `get_ai_provider()` (AC10 enforced at the module-import level, not just UI). Renamed `photo_service._upload_from_bytes` → `upload_from_bytes` (now a declared shared helper; one existing call site in `save_business_photo()` unaffected in behavior). Data model impact: none — reuses `User.avatar_url` verbatim. Cache: no invalidation needed (`search:*` doesn't embed `avatar_url`; `reviews.py` GETs aren't cached at all). Old avatar file is deleted best-effort on replace (safe no-op on external/legacy URLs per both storage providers' behavior — documented in Risks). Frontend: new reusable `Avatar` UI primitive (image-or-initials, `onError` fallback) used by both `Navbar.tsx` and `ProfilePage.tsx`; new `auth.uploadAvatar()` in `api.ts` following `photos.upload()`'s multipart pattern; Navbar↔ProfilePage live sync via a scoped `window` `CustomEvent` (`mh:user-updated`) rather than a new global store, to satisfy AC5 without a disproportionate refactor. RBAC matrix: identical across all three roles (own-avatar-only, no admin bypass). No ADR warranted (routing/module-boundary call, not a new integration or auth change). Status: Draft → **Specified** — handing off to Builder. |
