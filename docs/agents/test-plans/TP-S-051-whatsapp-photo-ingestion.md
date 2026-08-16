# TP-S-051: WhatsApp photo ingestion — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-051 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

Bound-session images through `save_business_photo`. No new UI.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `TestPhotos::test_bound_image_creates_general_photo` |
| 2 | Automated | same — `photo_type == general` on public gallery GET |
| 3 | Automated | `test_unbound_image_is_ignored` |
| 4 | Automated | `test_failed_media_does_not_create_photo` (`mock-media-fail`) |
| 5 | Automated | `test_video_is_not_stored` |
| 6 | Manual / existing photo UI | AI labels stay suggestion-copy (shared upload path; no new WhatsApp “verified” copy) |
| 7 | Automated | unbound image (AC3) is the ingest grant |
| 8 | Automated | mock PNG, no Meta |

---

## Environment

- `WHATSAPP_PROVIDER=mock`
- Local storage provider in pytest
