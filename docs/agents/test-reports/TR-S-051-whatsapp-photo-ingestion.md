# TR-S-051: WhatsApp photo ingestion — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-051 |
| **Author** | Tester |
| **Date** | 2026-08-16 |
| **Recommendation** | Rework |

---

## Summary

Photo cases live in `test_whatsapp.py::TestPhotos`. They were **not run** on this host (same pytest blocker as S-050). Implementation uses `save_business_photo` with `photo_type=general`. Failed media and video paths exist in tests.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Bound image via shared save path | A | `test_bound_image_creates_general_photo` | Not run |
| 2 | Gallery `photo_type=general` | A | same | Not run |
| 3 | Unbound image ignored | A | `test_unbound_image_is_ignored` | Not run |
| 4 | Download fail, no Photo | A | `test_failed_media_does_not_create_photo` | Not run |
| 5 | Video not stored | A | `test_video_is_not_stored` | Not run |
| 6 | AI labels remain suggestions | M | shared photo path; no new “verified from WhatsApp” copy | Pass (review) |
| 7 | Binding is the only ingest grant | A | unbound test | Not run |
| 8 | Mock fixture PNG | A | mock provider `MOCK_PNG` | Not run |

**Coverage:** 8/8 mapped; pytest **Not run**.

---

## Backend tests

### Added

- `TestPhotos` in `backend/tests/test_whatsapp.py`

### Run output

```
Not executed (no Docker / no backend venv on this host).
```

---

## Frontend tests

None required (no new screen).

---

## Gaps / rework items

1. Run pytest `TestPhotos` before Accept.
2. Ack copy for failed download is not asserted (handler sends it; mock only logs).

---

## Sign-off

- [x] All AC mapped
- [ ] RBAC/bind tests executed
- [x] AI disclaimer: no new verified claim
- [ ] Ready for PM acceptance
