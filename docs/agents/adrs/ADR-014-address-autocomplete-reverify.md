# ADR-014: Address autocomplete via existing Nominatim provider + OTP-gated re-edits

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-18 |
| **Slice** | S-073 |

---

## Context

S-073 asks for two independent things that both touch the existing address-entry path
in `BusinessForm.tsx` / `app/routers/maps.py`:

1. Live, as-you-type address suggestions that pre-fill city/postal code (today's
   `GET /maps/geocode` only returns a single best-match lat/lng on button click, no
   suggestion list, no structured address components).
2. An OTP re-verification gate on the *second and later* edit to an existing business's
   address (never on first creation or first edit).

Both need a provider/mechanism decision before the Builder starts, since either could
plausibly be re-implemented from scratch instead of reused.

---

## Decision

1. **Autocomplete stays on Nominatim (OpenStreetMap)** — the same provider
   `GET /maps/geocode` already calls, per ADR precedent (`README.md` §4: OSM tiles +
   Nominatim, "Google Maps env vars are unused leftovers"). No new provider, no new API
   key, no new env var. A new backend function `search_addresses()` is added to
   `app/services/geo.py` (business logic in services, per CLAUDE.md layering — the
   existing `geocode_address` handler being inline in the router is pre-existing debt,
   not repeated here) that calls Nominatim's `/search` with `limit=5&addressdetails=1`
   instead of `geocode_address`'s `limit=1` (no `addressdetails`), and maps
   `address.city`/`address.town`/`address.village` → `city`, `address.postcode` →
   `postal_code`. Exposed as a new `GET /maps/autocomplete?q=` endpoint — a new endpoint
   rather than changing `GET /maps/geocode`'s contract, since other callers (button-click
   geocode, `README.md` §7) depend on today's single-result shape.

2. **Re-verification reuses `app/services/phone_otp.py` primitives** (`issue_otp`,
   `consume_otp`), exactly as ADR-013 does for S-070's mock Aadhaar step, and exactly as
   S-073's own dependency note requests ("reuse S-044's OTP mechanism pattern"). The code
   *is* sent via the real `get_sms_provider()` to the merchant's phone (business phone,
   falling back to the merchant user's account phone) — unlike S-070's Aadhaar mock, this
   reuses the *real* SMS-delivery path since it's gating a real state change (business
   address), not simulating a government check. Redis key: `bizaddr:{business_id}`.

3. **Edit-count tracking is a new `businesses.address_edit_count` integer column**
   (default `0`), incremented only when an update actually changes an address-bearing
   field (`address`, `city`, `state`, `postal_code`, `country`). `PATCH /businesses/{id}`
   requires a verified `address_otp_code` in the payload only when
   `address_edit_count >= 1` **and** the payload changes an address field. This is the
   minimal new column needed — no new table, no edit-history log (not asked for by any
   AC).

---

## Consequences

### Positive
- Zero new external dependencies or credentials.
- One additional integer column, additive to `Business`, non-breaking migration.
- OTP delivery reuses the exact tested SMS abstraction (`get_sms_provider()`).

### Negative / tradeoffs
- Nominatim's public instance has an informal 1 req/sec usage policy; live-as-you-type
  autocomplete increases request volume versus today's button-click-only geocode. The
  frontend must debounce (≥300ms) and only fire once ≥3 characters are typed (per AC1) —
  this is a client-side mitigation, not a backend rate limit, and is called out as a risk
  in the slice's Risks section for the Tester to watch for 429/502 from Nominatim under
  rapid typing in manual QA.
- Reusing `phone_otp.py`'s Redis key space with a distinguishing prefix, rather than
  refactoring it into a shared generic OTP module, means two near-identical call sites
  (`auth.py`, this slice's business-address flow, and ADR-013's mock-Aadhaar flow) all
  import the same two functions directly. Acceptable now (three call sites, no
  divergence in behavior needed); revisit as a shared `otp_store.py` extraction if a
  fourth consumer appears.

### Follow-ups
- If Nominatim rate-limiting becomes a real problem in production, consider a self-hosted
  Nominatim instance or a debounce increase — not a provider swap (out of scope per the
  slice's own "Out of scope" section).

---

## Alternatives considered

1. Google Places Autocomplete — rejected: introduces a new paid provider/API key
   contradicting `README.md` §4's explicit OSM-only maps decision; Google Maps env vars
   already exist as unused leftovers precisely because this call was made before.
2. A dedicated `address_verification_totp.py` module — rejected as unnecessary
   duplication of `phone_otp.py`'s proven Redis/TTL/hash pattern (see Decision §2).
3. Storing full address-edit history (audit table) instead of a simple counter —
   rejected: no AC asks for history/audit, only "was this edited before" — YAGNI.
