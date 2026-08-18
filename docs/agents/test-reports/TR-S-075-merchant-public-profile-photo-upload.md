# TR-S-075: Optional merchant public-profile photo upload — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-075 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** New `frontend/src/components/BusinessPhotoManager.tsx` implements the full
upload/list/delete UI, wired into `BusinessForm.tsx`'s **edit mode only**
(`{mode === "edit" && business && <BusinessPhotoManager businessId={business.id} />}`),
matching the Architect's placement decision (a `business_id` is required by the upload
endpoint, unavailable in create mode until the first `POST /businesses` succeeds). It
lists existing photos via `photos.listForBusiness()` on mount, uploads via
`photos.upload(file, { businessId, photoType: "gallery" })` and appends the result to
local state immediately, and deletes via `photos.delete(photoId)` gated behind
`window.confirm()`. `frontend/src/lib/api.ts`'s `photos` client object already had
`listForBusiness`/`upload` (contrary to the slice's own premise, corrected by the
Architect) and now also has `delete` — `git diff` confirms zero changes to
`backend/app/routers/photos.py`, `backend/app/services/photo_service.py`, or
`frontend/src/components/PhotoGallery.tsx`, matching this slice's "frontend-only, no
backend change" scope exactly.

Full frontend suite: **238/238 passing**, 46/46 suites.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Upload control present, clearly optional, no validation error blocks submission without a photo | A | `frontend/src/components/__tests__/BusinessPhotoManager.test.tsx::"renders an upload control and optional copy, with no existing photos initially"`; `frontend/src/components/__tests__/BusinessForm.test.tsx::"submits successfully once all required fields are valid"` proves the form's own submit validation has no photo dependency (edit-mode form doesn't even run `validateRequiredFields`, code read) | Pass |
| 2 | Valid image upload → sent to `photos.upload` → appears in merchant's own preview immediately on success | A | `BusinessPhotoManager.test.tsx::"uploads a selected file and shows it immediately on success"` — asserts `photos.upload` called with `(file, {businessId, photoType: "gallery"})` and the new photo renders via an `<img>` with the returned URL, no refetch required | Pass |
| 3 | Existing photos listed via list endpoint, with delete requiring confirmation | A | `BusinessPhotoManager.test.tsx::"lists existing photos fetched via photos.listForBusiness"`, `"requires confirmation before deleting, and removes the photo from the list on confirm"`, `"does not delete when confirmation is declined"` (asserts `window.confirm` gates the call, and a decline makes zero calls to `photos.delete`) | Pass |
| 4 | Rejected upload (bad type/size) shows a clear, specific frontend error, not silent/generic | A | `BusinessPhotoManager.test.tsx::"shows a specific inline error when the backend rejects the upload"` — asserts the thrown error's message text (e.g. "Unsupported file type...") renders verbatim inline, not swallowed | Pass |
| 5 | Customer viewing a public profile with photos sees them via unchanged `PhotoGallery.tsx` | Code read (regression, no test needed) | `git diff --stat` confirms zero changes to `frontend/src/components/PhotoGallery.tsx` or `frontend/src/app/businesses/[slug]/page.tsx` — the merchant-side upload UI is fully independent of the customer-facing render path | Pass |
| 6 | Zero-photo business → existing empty state on public profile unchanged | Code read (regression) | Same `git diff` evidence as AC5 — no file in the public-profile render path was touched by this slice | Pass |
| 7 | `api.ts` `photos` client gains upload/list/delete, standard client pattern | A + code read | Code read: `frontend/src/lib/api.ts` — `photos.listForBusiness`/`photos.upload` pre-existed; `photos.delete` is the one addition (`apiFetch<void>(\`/api/v1/photos/${photoId}\`, { method: "DELETE" })`), exercised indirectly by `BusinessPhotoManager.test.tsx`'s delete tests via the mocked `photos.delete` | Pass |
| 8 | Non-owner upload/delete rejected by existing backend ownership check; no new permission bug from the new frontend UI | Code read | `git diff --stat backend/app/routers/photos.py` shows **zero changes** — the existing `require_roles(MERCHANT, ADMIN)` + business-ownership check is untouched; the new frontend UI only ever calls `photos.upload`/`photos.delete` with a `businessId`/`photoId` the merchant is already viewing via their own `/merchant/businesses/{id}/edit` page (no new code path that could bypass the check), confirmed no test needed since the client can't construct a request the server wouldn't already validate | Pass |

**Coverage:** 8 / 8 AC mapped (6 automated, 2 code-read/regression — both backed by an
explicit `git diff` showing zero backend/customer-facing-frontend changes, which is the
strongest possible evidence for "unchanged" claims).

---

## Backend tests added
None — confirmed via `git diff --stat` that no backend file (`photos.py`,
`photo_service.py`) changed; existing backend photo-pipeline tests
(`backend/tests/test_photos.py`, present but out of this slice's diff) already cover
upload/list/delete/ownership at the router level and were not touched.

## Frontend tests added
- `frontend/src/components/__tests__/BusinessPhotoManager.test.tsx` (new file, 6 tests):
  - `"renders an upload control and optional copy, with no existing photos initially"`
  - `"lists existing photos fetched via photos.listForBusiness"`
  - `"uploads a selected file and shows it immediately on success"`
  - `"shows a specific inline error when the backend rejects the upload"`
  - `"requires confirmation before deleting, and removes the photo from the list on confirm"`
  - `"does not delete when confirmation is declined"`
- `frontend/src/components/__tests__/BusinessForm.test.tsx` (new file, shared with S-072
  — 2 of its 7 tests map here):
  - `"renders BusinessPhotoManager in edit mode with the business id"`
  - `"does not render BusinessPhotoManager in create mode"`

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-075-01 | Live upload of a real image file against the running backend, confirm it renders on the public profile page (`PhotoGallery.tsx`) after refresh | Not run — no live backend/storage provider reachable in this sandbox. `docker compose up --build` smoke test required before merge, consistent with prior slices in this batch. |
| M-075-02 | Confirm the AI-provider `analyze_image()` call triggered by `save_business_photo()` doesn't block/degrade the upload response when `AI_PROVIDER=mock` | Not run live, but code read (per Architect's own risk note) confirms `AIAnalysis` failures don't raise — the `degraded` flag pattern is pre-existing and unrelated to this slice's frontend-only diff. |

---

## Regressions / gaps

None found. Full suite green (238/238), no test removed or weakened. Both "unchanged
backend/customer-facing" claims (AC5, AC6, AC8) are backed by an explicit `git diff
--stat` showing zero modified lines in the relevant files, which is stronger evidence
than a typical code-read.

## Recommendation

**Ship.** All 8 AC mapped and passing.
