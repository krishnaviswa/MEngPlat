# Slice: S-060 — Mobile merchant dashboard analytics (parity for M-61)

| Field | Value |
|-------|-------|
| **Slice ID** | S-060 |
| **Phase** | 4 Dashboards |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-18 |

---

## User story

**As a** merchant using the mobile app
**I want** the same review-volume time-series chart, 1–5 star rating mix, a date-range filter
(last 30 days / last 90 days / all time), a reply-rate figure, and an optional CSV export of my
own business's reviews that I already have on the web dashboard
**So that** I'm not forced to open a browser or a laptop just to see how my business is trending —
the phone app gives me the same real, DB-derived numbers, not a cut-down or mocked-up view

---

## Acceptance criteria

Numbered to parity-match S-033's 8 web AC one-for-one, adapted to Flutter/mobile after reading
S-033 in full and directly inspecting `mobile/lib/features/merchant/merchant_dashboard_screen.dart`,
`mobile/lib/features/merchant/dashboard_repository.dart`, and the generated API client
(`mobile/packages/merchanthub_api/lib/src/api/dashboard_api.dart`) — see "Current state verified"
in UX notes. This slice does **not** scope in M-68's area/line trend charts or period-over-period
delta badges (S-037, a separate later slice) — see Out of scope.

1. **(Parity for S-033 AC 1 — volume chart)** Given I am signed in as a merchant on the mobile
   dashboard (`merchant_dashboard_screen.dart`) with a selected business whose dashboard payload
   already includes `review_volume_by_month` (confirmed present in `DashboardStats` today, just
   unused by the mobile screen), when the dashboard loads, then that series is rendered as a
   visible chart (review volume over months) — no longer unused payload on mobile either.
2. **(Parity for S-033 AC 2 — rating mix)** Given the selected business has reviews with star
   ratings, when I view the mobile dashboard, then I see a 1–5 star rating distribution
   (`rating_distribution`, already present in `DashboardStats` today, currently unused by mobile)
   rendered as counts or proportions per star bucket — same DB-computed source as web, no new
   client-side computation of a value the backend already provides.
3. **(Parity for S-033 AC 3 — date range)** Given I am on the mobile dashboard, when I choose a
   date range of last 30 days, last 90 days, or all time, then review volume, rating mix, and
   reply-rate (AC 5) update to reflect that range, using the existing `range=30|90|all` query
   parameter already supported by `GET /api/v1/dashboard/merchant/{business_id}` (confirmed
   present and wired through the generated `dashboard_api.dart` client) — not a client-side filter
   of an already-fetched all-time payload.
4. **(Parity for S-033 AC 4 — AI trend disclaimer)** Given AI `monthly_trends` are shown anywhere
   on the mobile dashboard (e.g. within the existing `AiInsightsPanel`), when those figures are
   not derived from stored review dates, then they are labeled as mock or degraded **and** carry
   suggestion language (never a definitive judgment of the business), matching the existing
   `AiInsightsPanel` disclaimer pattern already shipped on mobile (S-031). When they *are*
   DB-derived, they may appear as trends but still with the same required suggestion/disclaimer
   copy.
5. **(Parity for S-033 AC 5 — reply-rate)** Given a selected date range (AC 3), when reply-rate is
   shown on the mobile dashboard, then it equals the existing `reply_rate` field already present
   in `DashboardStats` for that range and business — `null` (zero reviews in range) is shown as
   clear "no reviews in this range" copy, not `0%`, matching AC 8's empty-state requirement and
   web's own null-handling precedent.
6. **(Parity for S-033 AC 6 — CSV export)** Given I am the merchant for the selected, currently
   loaded business, when I choose to export, then I can optionally trigger a CSV download/share of
   that business's reviews (own business only) via the existing, unmodified
   `GET /api/v1/dashboard/merchant/{business_id}/reviews.csv?range=...` endpoint (confirmed already
   present and wired through the generated client) — the mobile-native equivalent of web's
   browser download is saving/sharing the file through the device's standard file/share mechanism.
   Export is optional; it is not required to read the charts. A merchant cannot export another
   merchant's reviews (enforced by the existing backend ownership check, unchanged).
7. **(Parity for S-033 AC 7 — permission cases)** Given a customer (there is no customer-role path
   to this screen at all — the dashboard route is already merchant-gated, see AC 8 of S-059's
   precedent) or a merchant who does not own the selected business attempts to load its dashboard
   stats or CSV export, when the request is made, then it is denied by the existing, unmodified
   backend RBAC (`403`) — this slice adds no new client-side bypass and relies on the same
   ownership check web already uses. Admin mobile dashboard behavior is unchanged by this slice
   (no admin analytics screen is introduced or altered).
8. **(Parity for S-033 AC 8 — empty range)** Given the selected business and date range contain no
   reviews, when the mobile dashboard renders the volume chart, rating mix, and reply-rate for that
   range, then I see an empty chart plus beginner-friendly copy (no crash, no blank unexplained
   failure, no fake series invented to fill the gap) — mirrors web's empty-range handling.

---

## UX notes

- **Screens / routes affected:** `mobile/lib/features/merchant/merchant_dashboard_screen.dart`
  only. No new mobile route. Matches S-033's own web scope ("`/merchant/dashboard` only").
- **Current state verified (not assumed) before writing these AC:**
  - `merchant_dashboard_screen.dart` today shows three static stat tiles (`totalReviewsTile`,
    `averageRatingTile`, `statusTile`), a `SentimentBreakdown` widget, an `AiInsightsPanel`, and a
    recent-reviews list — all from S-031/S-022/S-058/S-059 work. It has **no chart of any kind**,
    **no date-range control**, **no reply-rate display**, and **no CSV export action** — confirmed
    by reading the full file (346 lines).
  - `mobile/lib/features/merchant/dashboard_repository.dart`'s `merchantStats(businessId)` calls
    `merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId: businessId)` with **no
    `range` argument passed** — the generated client method accepts an optional `range` parameter
    (default `'all'`, confirmed in `dashboard_api.dart` line 480) that the mobile repository simply
    never forwards today.
  - `DashboardStats` (`mobile/packages/merchanthub_api/lib/src/model/dashboard_stats.dart`,
    generated from the backend's OpenAPI spec) **already includes** `ratingDistribution` and
    `replyRate` fields (confirmed by grep) — the same fields S-033 added on the backend. Mobile's
    generated API client is not behind the backend; the screen simply doesn't read or render them
    yet.
  - The CSV endpoint (`GET /api/v1/dashboard/merchant/{business_id}/reviews.csv`) is **already
    present and fully wired** in the generated client —
    `merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId, range)`
    (confirmed in `dashboard_api.dart` lines 551-596), including the `range` query param and
    returning a `JsonObject`/raw response suitable for a file body. `DashboardRepository` has no
    method calling it yet.
  - **Conclusion: no backend gap.** Every field and endpoint AC 1-6 need already exists,
    unmodified, and is already generated into the mobile OpenAPI client — this is a mobile-UI-only
    slice, the same standard S-040/S-057/S-058/S-059 held themselves to. The only backend-adjacent
    work is the mobile `DashboardRepository` starting to pass `range` and add a CSV-fetch method,
    both pure client-side wiring against endpoints that already work (confirmed by S-033's own
    Accepted, tested web implementation exercising the identical endpoints).
  - `mobile/lib/features/merchant/ai_insights_panel.dart` already renders `monthly_trends` with
    suggestion/degraded language per S-031 — AC 4 here should confirm/extend that existing pattern
    rather than reinvent it; Architect to confirm during implementation whether any gap actually
    exists or whether AC 4 is already satisfied as-is (S-033's AC 4 required web-side work because
    web's `AIInsights.tsx` was feeding trends into a fact chart — mobile's `AiInsightsPanel` may
    not have that problem; Architect should verify, not assume parity of the underlying bug).
  - No Flutter charting package currently in `mobile/pubspec.yaml` was confirmed present or absent
    by this PM pass — Architect must grep and name the exact package (e.g. `fl_chart`, already
    a common Flutter-ecosystem choice) in the technical specification, mirroring how S-059 named
    `qr_flutter`/`share_plus` explicitly rather than leaving Builder to pick blind.
  - No file-save/share package was confirmed present or absent for the CSV export (AC 6) — note
    `share_plus` was added in S-059 for a different purpose (sharing a review-collection link);
    Architect should check whether it's already available in `pubspec.yaml` by the time this slice
    is implemented (S-059 may have shipped first) and whether it's reusable for sharing/saving a
    CSV file, or whether a dedicated file-save package (e.g. `path_provider` + a share/open call)
    is needed instead.
- **Components to reuse:** `merchant_dashboard_screen.dart` itself (extend, not replace), the
  existing `DashboardStats` model fields, the existing `DashboardRepository` (extend with `range`
  passthrough + a new CSV-fetch method), `SentimentBreakdown` (existing 1-5 breakdown widget —
  Architect should check whether this can be reused/adapted for AC 2's rating mix instead of
  building a second, separate rating-distribution widget, since `SentimentBreakdown` may already
  render a similar 1-5 style shape; verify before assuming a new widget is needed).
- **Empty states / errors:** Empty range → empty chart + clear copy (AC 8), same pattern as web.
  Export denial for the wrong business is a permission failure surfaced clearly (existing
  `ApiException`/error-copy pattern already used elsewhere in this screen for `_error`), not a
  silently empty or corrupt file.
- **AI disclaimer required?** Yes — no new AI surface is introduced by this slice, but the
  existing `AiInsightsPanel` trend disclaimer (AC 4) must continue to read as a suggestion, never
  a definitive judgment, exactly as it already does today per S-031/S-033 web precedent.

---

## Out of scope

- **M-68's own line item** (dashboard area/line trend charts with period-over-period delta badges,
  web ref S-037) — a separate, later Tier 3 slice. This slice's volume chart is the same simple
  "volume over months" chart S-033 shipped on web, not S-037's richer trend/delta treatment. The
  Architect should flag any implementation overlap (e.g. if the same charting package or the same
  screen section would sensibly host both) as a dependency/ordering note for whoever picks up
  M-68 next, but must not scope S-037's delta-badge or area/line-trend work into this slice.
- **Any change to web code.** `frontend/` is untouched — S-033 already shipped there and is
  Accepted.
- **Any new backend endpoint, schema, or migration** — confirmed not needed; every field and route
  this slice's AC depend on already exists, unmodified, and is already present in the generated
  mobile OpenAPI client.
- **Revenue, cohorts, or payment analytics** — same boundary S-033 drew (belongs to M-66/S-036).
- **Ad funnels or campaign attribution.**
- **New AI insight types** beyond honestly labeling the existing `monthly_trends` (same as S-033).
- **Admin analytics as a product** — unrelated (M-... admin analytics parity, if any, is a
  separate tracker row); admin mobile behavior is unchanged by this slice.
- **True OS-level file-system integration beyond a standard share/save action** for the CSV
  export — a basic native share-sheet or file-save flow satisfies AC 6; this slice does not scope
  in a dedicated "Downloads" screen or file-management UI within the app.

---

## Dependencies

- **S-033 (web merchant analytics) — Accepted.** This slice parity-matches its 8 AC; Architect
  should read `docs/agents/slices/S-033-merchant-analytics.md` in full for the reference backend
  contract (`range` query param, `rating_distribution`, `reply_rate`, CSV endpoint semantics,
  UTC date handling, null-on-zero reply-rate) — all of it already shipped and is reused as-is,
  not reimplemented.
- **S-031 (mobile merchant dashboard shell, stat tiles, `AiInsightsPanel`)** — the screen and
  providers this slice extends already exist from that slice.
- **S-058 / S-059 (mobile review-list interactivity, review-collection flow)** — both Accepted,
  both touch the same dashboard screen/file; not a hard blocker, but Architect/Builder should
  confirm no merge-conflict-shaped overlap with the "Share review link" button S-059 added to the
  same screen.
- Not blocked on M-68/S-037 (explicitly out of scope, see above) — this is the first Tier 3 item
  picked up per the mobile parity roadmap (`README.md` §12), Tier 1 and Tier 2 now fully closed.

---

## Definition of done (PM)

- [x] All AC verified in test report (`TR-S-060-mobile-dashboard-analytics.md`) — all 8 AC Pass
- [x] UX matches notes above, including the Architect's explicit confirmation of the charting
      package (`fl_chart`) and CSV file-save/share mechanism (`share_plus`, reused from S-059)
- [x] Documented in `README.md` §8 Frontend guide (Mobile client section) — new
      `fl_chart`/`share_plus`-file-sharing conventions noted for reuse by future slices (e.g. M-68)
- [x] `README.md` §12 Web ↔ mobile feature parity tracker — M-61 row updated to `implemented`
      (all 8 AC pass with no deferral)
- [x] `README.md` §12 Mobile parity roadmap Tier 3 annotated with M-61 closed
- [x] `README.md` §14 and §16 updated to reflect the closed mobile gap
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

> Specified 2026-08-18. **No backend gap — confirmed by direct inspection**, same conclusion the
> PM already reached. This slice is mobile-client-only: `DashboardRepository` starts forwarding
> `range` and gains a CSV-fetch method against endpoints S-033 already shipped, unmodified.

### API contract

**None new.** Both endpoints already exist, unmodified, on the backend (`backend/app/routers/dashboard.py`,
S-033) and are already generated into `mobile/packages/merchanthub_api/lib/src/api/dashboard_api.dart`.
This slice only starts *calling* them correctly from `DashboardRepository`.

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `GET` | `/api/v1/dashboard/merchant/{business_id}` | Bearer; `require_roles(MERCHANT, ADMIN)` (unchanged) | Path: `business_id` UUID. Query: `range=30\|90\|all` (default `all`, existing). | `DashboardStats` — existing fields `total_reviews`, `average_rating`, `sentiment_breakdown`, `recent_reviews`, plus already-present-but-mobile-unused `review_volume_by_month` (`list[{month, count}]`), `rating_distribution` (`dict["1".."5", int]`), `reply_rate` (`float 0-1` or `null`). | Generated client method: `merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId, range: ...)` — `dashboard_api.dart:478`. `DashboardRepository.merchantStats` today calls this **without** forwarding `range`; this slice adds a `String range = 'all'` parameter and passes it through. |
| `GET` | `/api/v1/dashboard/merchant/{business_id}/reviews.csv` | Same as above | Path: `business_id` UUID. Query: `range=30\|90\|all` (default `all`). | `text/csv` attachment (`Content-Disposition: attachment; filename="reviews-{business_id}-{range}.csv"`). | Generated client method: `merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId, range: ...)` — `dashboard_api.dart:566`, returns `Response<JsonObject>`. **Codegen note for Builder:** Dio's default transformer does not JSON-decode a `text/csv` body (content-type isn't `application/json`), so `_response.data` arrives as a raw `String`; the generated code then runs it through `_serializers.deserialize(..., FullType(JsonObject))`, which for `JsonObject` is a pass-through wrapper (no actual JSON parsing attempted) — so `response.data!.value` should resolve to the raw CSV text as a `String`. Builder must verify this empirically against a real response (e.g. a quick manual/integration check) before relying on it, since it depends on built_value's `JsonObject` serializer behavior, not something to assume blind. |
| `GET` | `/api/v1/ai/businesses/{business_id}/insights` | Existing | Unchanged | Unchanged `MerchantInsightsResponse` incl. `monthly_trends`, `degraded` | Already called via `DashboardRepository.insights`/`AiInsightsPanel` (S-031). AC 4 reuses this path as-is — see AC 4 note below; no change expected. |

No new backend route, Pydantic schema, SQLAlchemy model, or migration.

**AC 4 (AI disclaimer) — confirmed, not assumed:** read `ai_insights_panel.dart` in full. It
already renders `monthly_trends`/`degraded` with suggestion-language copy and a
mock/degraded label, matching the exact S-031/S-033 disclaimer pattern web uses — **no gap
exists**. AC 4 requires no code change; it is satisfied as-is. Builder should not touch
`ai_insights_panel.dart` for this slice unless a genuine regression is found during
implementation (not expected).

### RBAC matrix

| Action | customer | merchant (owner) | merchant (other business) | admin |
|--------|----------|-------------------|----------------------------|-------|
| `GET` dashboard stats (`range` now forwarded) | 403 (unchanged backend gate) | 200 | 403 (unchanged backend gate) | 200 (unchanged, view-as-today) |
| `GET` reviews.csv | 403 (unchanged backend gate) | 200 | 403 (unchanged backend gate) | 200 (unchanged) |
| Mobile dashboard route (`merchant_dashboard_screen.dart`) | No route (screen is merchant-only shell, S-031; customer never reaches this screen — see AC 7) | Reachable, own businesses only (`ownedBusinessesProvider`) | N/A (business selector only lists the signed-in merchant's own businesses) | Not this slice's admin analytics; unchanged |
| Volume chart / rating mix / reply-rate / CSV export controls on that screen | N/A (no route access) | Visible for whichever business is selected in the existing `merchantBusinessSelector` dropdown | N/A | N/A (no admin analytics screen introduced) |

Matches S-033's already-accepted backend RBAC exactly — this slice adds no new client-side
bypass and introduces no new server-side check; the 403 cases above are the existing backend
gate, exercised for the first time from the mobile client with a non-`all` `range` value and
from the new CSV call.

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No new tables, columns, enums, or Alembic migration. No change to
`backend/app/schemas/__init__.py` — `DashboardStats` already carries every field this slice
needs (`ratingDistribution`, `replyRate`, `reviewVolumeByMonth`, confirmed by grep against the
generated `dashboard_stats.dart`). ERD in README §5: no update.

### Cache / side effects

- No Redis change. Dashboard GET already skips `search:*` (S-033, unchanged); CSV is generated
  per-request, uncached (unchanged). This slice adds no new write path, so no new invalidation.
- Client-side: no new persistent cache. `_stats` stays a per-screen `State` field
  (`merchant_dashboard_screen.dart`'s existing pattern) — selecting a new date range triggers a
  fresh `_loadDashboard(business.id, range: ...)` call rather than a client-side filter of an
  already-fetched all-time payload (AC 3's explicit requirement). No provider-level caching by
  `range` is introduced; each range change is a live network round trip, matching web's own
  behavior (S-033: "refetch on change").

### Frontend

- **Route:** `mobile/lib/features/merchant/merchant_dashboard_screen.dart` only. No new route,
  matching S-033's own web scope and the PM's UX notes.
- **Rendering:** n/a (Flutter) — Dart/Riverpod `ConsumerStatefulWidget` state, no SSR/CSR
  distinction (mobile).
- **Charting package decision — `fl_chart`:** no charting package exists in `pubspec.yaml`
  today (confirmed by reading the full dependency list). **Chosen: [`fl_chart`](https://pub.dev/packages/fl_chart)**
  — it is the de facto standard Flutter charting library (actively maintained, large adoption,
  pure-Dart/no native platform channel, covers both the bar/line chart AC 1 needs for
  "volume over months" and the bar chart AC 2 needs for the 1-5 rating mix with one dependency,
  avoiding a second package for a second chart shape). Add to `pubspec.yaml` as
  `fl_chart: ^1.1.1` (Builder: pin to whatever is the actual current latest stable at
  implementation time, matching the caret-range style already used for every other dependency).
  This is the first charting-package convention on mobile — note it in `README.md` §8 Frontend
  guide when Builder implements (per repo convention: new component/pattern → §8).
- **CSV save/share mechanism decision — reuse `share_plus`, no new package:** confirmed by
  reading `share_plus_platform_interface-7.2.0`'s `ShareParams` (the type `share_plus: ^13.3.0`,
  added in S-059, is built on) that it supports `files: List<XFile>?` alongside `text` — i.e.
  `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: '...', mimeType: 'text/csv')]))`
  shares raw in-memory bytes through the native share sheet, **no temp-file write and no
  `path_provider` needed**. This is a strict superset of S-059's existing `ShareParams(text: ...)`
  usage in `share_review_link_sheet.dart` — same package, same instance call, different
  parameter. **Decision: reuse `share_plus`, add no new package for CSV export.** The CSV text
  string (see API contract note above) is UTF-8 encoded to bytes
  (`Uint8List.fromList(utf8.encode(csvText))`) and passed as a single `XFile.fromData(...,
  name: 'reviews-$businessId-$range.csv', mimeType: 'text/csv')`. This satisfies AC 6's "mobile
  equivalent of web's browser download" via the OS's standard native share/save sheet (the user
  can save to Files/Drive/etc. from there) — matching the Out-of-scope note that a dedicated
  in-app "Downloads" screen is not required.
- **Components (reuse first):**
  - `merchant_dashboard_screen.dart` (**modified**) — extend, not replace:
    - Add a date-range control (e.g. `SegmentedButton<String>` or three `ChoiceChip`s, key
      `dashboardRangeSelector`) with values `30` / `90` / `all` (default `all`, matching the
      backend default and AC 3). Changing it re-triggers `_loadDashboard(business.id, range:
      selected)` — a live refetch, not a client-side filter (see Cache section).
    - Add a volume chart section (new key `reviewVolumeChart`) rendering `_stats.reviewVolumeByMonth`
      via `fl_chart`'s `BarChart` (or `LineChart` — Builder's call between the two `fl_chart`
      widget types; both satisfy AC 1's "volume over months" requirement, bar chart is the
      closer visual match to S-033's web `Charts.tsx` reference and is the recommended default).
      Empty range (AC 8) → empty-state copy (e.g. "No reviews in this range"), not an empty/blank
      chart canvas with no explanation — same requirement as web's `Charts` `emptyMessage` prop
      (S-033), reused as an equivalent Dart conditional rather than a literal prop port.
    - Add a reply-rate stat (extend the existing `_StatTile` row or add a fourth tile, key
      `replyRateTile`): `_stats.replyRate == null` → "No reviews in this range" copy (never
      `0%` — AC 5/AC 8's explicit null-vs-zero requirement, same as web's precedent); otherwise
      render as a percentage.
    - Add a CSV export action (`OutlinedButton`/`IconButton`, key `exportCsvButton`) near the
      existing "Share review link" button, calling the new repository method and then
      `SharePlus.instance.share(...)` per the decision above. Export failure (e.g. wrong-business
      403, though the UI should never let a merchant select another merchant's business in the
      first place, so this is primarily a defense-in-depth/network-error path) surfaces through
      the existing `_error`/`ApiException` pattern already used elsewhere on this screen — not a
      silent empty file (AC 6's explicit requirement, mirrors S-033's own risk note).
  - **`SentimentBreakdown` reuse decision for AC 2 (rating mix):** read
    `sentiment_breakdown.dart` in full — it renders **positive/neutral/negative** sentiment
    buckets (`counts['positive'|'neutral'|'negative']`), a materially different shape from AC 2's
    1-5 **star rating** distribution (`rating_distribution` keys `"1"`-`"5"`). These are two
    different DB-computed dimensions already both present in `DashboardStats`
    (`sentimentBreakdown` vs `ratingDistribution`) and already serve two different purposes on
    the existing screen (`SentimentBreakdown` is already wired to `sentimentBreakdown` today).
    **Decision: do not repurpose `SentimentBreakdown` for AC 2 — build a small new widget**,
    `mobile/lib/features/merchant/rating_distribution_chart.dart` (**new**, small, `fl_chart`
    horizontal/vertical `BarChart` over the 5 star buckets, same general shape/spirit as
    `SentimentBreakdown`'s existing bar-per-bucket layout for visual consistency, but a distinct
    widget because the data key set and semantic meaning genuinely differ). This keeps
    `SentimentBreakdown` untouched (no regression risk to its existing sentiment use) while
    giving AC 2 its own correctly-keyed widget.
  - `mobile/lib/features/merchant/dashboard_repository.dart` (**modified**):
    - `merchantStats(String businessId, {String range = 'all'})` — add the `range` parameter,
      forward it to `merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId: businessId,
      range: range)` (the generated method already accepts it; today's call simply omits it).
    - `reviewsCsv(String businessId, {String range = 'all'})` — **new** method, calls
      `merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId:
      businessId, range: range)`, extracts the raw CSV string per the API contract note above,
      and returns it (`Future<String>`) for the screen to UTF-8-encode and hand to `share_plus`.
      Same `try { ... } on DioException catch (e) { throw ApiException.fromDioException(e); }`
      pattern already used by every other method in this file.
  - `mobile/pubspec.yaml` (**modified**) — add `fl_chart: ^1.1.1` under `dependencies:`. No
    change needed for CSV export (`share_plus` already present from S-059).
- **M-68 overlap flag (per PM's explicit ask):** this slice's volume chart and M-68's future
  area/line trend + delta-badge work (S-037 web reference) will likely both live in or near the
  same dashboard section and may reasonably reuse the same `fl_chart` dependency once it exists
  on mobile — noted here as a dependency/ordering convenience for whoever picks up M-68 next, not
  scoped into this slice. Builder should not pre-build M-68's delta-badge UI now.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant Screen as merchant_dashboard_screen.dart
    participant Repo as DashboardRepository
    participant API as FastAPI /dashboard (S-033, unchanged)

    Merchant->>Screen: Open dashboard, business already selected
    Screen->>Repo: merchantStats(businessId, range: 'all')
    Repo->>API: GET /dashboard/merchant/{id}?range=all
    API-->>Repo: DashboardStats (volume, rating_distribution, reply_rate, ...)
    Repo-->>Screen: DashboardStats
    Screen->>Screen: Render fl_chart volume chart + rating mix + reply-rate tile

    Merchant->>Screen: Selects range = 30
    Screen->>Repo: merchantStats(businessId, range: '30')
    Repo->>API: GET /dashboard/merchant/{id}?range=30
    API-->>Repo: DashboardStats (filtered; reply_rate null if 0 in range)
    Repo-->>Screen: DashboardStats
    alt reviews exist in range
        Screen->>Screen: Update chart + mix + reply-rate %
    else empty range
        Screen->>Screen: Empty-state copy, no crash, no fake series (AC 8)
    end

    Merchant->>Screen: Taps "Export CSV"
    Screen->>Repo: reviewsCsv(businessId, range: '30')
    Repo->>API: GET /dashboard/merchant/{id}/reviews.csv?range=30
    alt owner or admin
        API-->>Repo: text/csv body
        Repo-->>Screen: CSV String
        Screen->>Screen: utf8.encode -> XFile.fromData
        Screen-->>Merchant: SharePlus.instance.share(ShareParams(files: [xfile]))
    else not owner
        API-->>Repo: 403
        Repo-->>Screen: ApiException
        Screen-->>Merchant: Error copy via existing _error pattern (not a silent empty CSV)
    end
```

### Architect checklist

- [x] API contract defined — no new endpoints; existing S-033 contract confirmed and cited by
      file/line, matching `README.md` §7 style
- [x] RBAC matrix complete — customer/merchant-owner/merchant-other/admin, matches existing
      backend gate exactly, no new surface
- [x] Data model impact documented — none, confirmed by grep against the generated schema
- [x] Cache invalidation considered — no Redis change; client-side range changes are live
      refetches, not a stale client cache
- [x] Uses AI/storage abstractions where applicable — AI path (`AiInsightsPanel`/`insights`)
      untouched, confirmed already-compliant with the suggestion/disclaimer requirement (AC 4);
      no `get_storage_provider()` usage needed (CSV is a direct streamed response, not stored)
- [x] ERD/API/FLOWS updates noted — none needed (no schema/endpoint change); README §8 (new
      `fl_chart` charting convention) and §12 (M-61 mobile row `unimplemented` → `implemented`)
      updates happen at Builder/Tester/PM handoff per repo convention, not here
- [x] Charting package named explicitly (`fl_chart`) — not left for Builder to guess
- [x] CSV mechanism named explicitly (`share_plus` file-share reuse, no new package) — not left
      for Builder to guess
- [x] No secrets in design

### Risks / tradeoffs

- **CSV `JsonObject` unwrapping is a codegen implementation detail, not verified end-to-end by
  this Architect pass** (no running backend/mobile app available in this review). Builder must
  confirm empirically (a quick manual call or a focused unit/integration test against a real or
  faked `text/csv` response) that `response.data!.value` actually yields the raw CSV string
  before wiring the share flow around it — if built_value's `JsonObject` deserializer behaves
  differently than reasoned above (e.g. throws on non-JSON input), the fallback is reading
  `_response.data` directly via a lower-level Dio call bypassing the generated wrapper, which is
  an acceptable, still-abstraction-respecting fallback (same generated `ApiClient`/`Dio`
  instance, just not routed through the one generated method whose typed return shape doesn't
  fit a CSV body cleanly). Flagging now so Builder isn't surprised mid-implementation.
- **`fl_chart` major-version churn:** `fl_chart` has had breaking API changes across past major
  versions (chart widget constructor shapes have shifted release to release). Builder should pin
  the actual current stable at implementation time (this spec's `^1.1.1` is illustrative, not
  gospel) and expect to read that version's own docs/examples rather than pattern-matching
  blindly off older `fl_chart` sample code that may be online.
- **`total_reviews`/`average_rating` tiles stay all-time, not range-filtered** — same decision
  S-033 made on web (existing `_StatTile`s are denormalized `Business` counters, unchanged
  meaning). Only the new volume chart, rating mix, and reply-rate respect the selected range,
  matching AC 3's exact wording ("review volume, rating mix, and reply-rate ... update"). Do not
  silently start range-filtering `totalReviewsTile`/`averageRatingTile` — that would change
  established tile semantics outside this slice's scope.
- **M-68 sequencing:** flagged above under Frontend — no action needed this slice, but Builder
  should avoid over-engineering the new volume-chart section in a way that would need throwaway
  rework once M-68's delta badges land (e.g. keep the chart in its own small widget rather than
  inlining it deep in `merchant_dashboard_screen.dart`'s build method, so a future S-037-mobile
  slice can extend it without a large diff).
- **No ADR needed:** this slice adds a new *package* (`fl_chart`) but not a new integration
  category, auth change, or schema pattern — same bar S-059 applied to `qr_flutter`/`share_plus`
  (no ADR). `fl_chart` is a pure-Dart rendering library with no backend/vendor/auth surface.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-060-*.md`
- Test report: `docs/agents/test-reports/TR-S-060-*.md`
- ADR: `docs/agents/adrs/ADR-XXX-*.md` (if any)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-18 | PM | Created slice. Mobile parity for M-61 (time-series volume, rating mix, date range, reply-rate, CSV on merchant dashboard), the first Tier 3 item in the mobile parity roadmap (`README.md` §12), picked up now that Tier 1 and Tier 2 are fully closed. Read S-033 (web reference, Accepted) in full first. Verified against the actual mobile codebase before writing AC (not assumed): `merchant_dashboard_screen.dart` has no chart, no date-range control, no reply-rate display, no CSV export today (S-031-era stat tiles/AI panel only); `DashboardRepository.merchantStats` never forwards a `range` argument even though the generated client method already accepts one (default `'all'`); the generated `DashboardStats` model already carries `ratingDistribution`/`replyRate` fields (mirrors S-033's backend schema, mobile client is not behind); the CSV endpoint is already fully generated into `dashboard_api.dart` including its `range` param. **Conclusion: no backend gap** — this is mobile-UI-only, same standard prior mobile-parity slices held themselves to. 8 numbered AC parity-matched one-for-one to S-033's 8 web AC (volume chart, rating mix, date range, AI-trend disclaimer, reply-rate incl. null-on-zero, optional own-business CSV export, permission cases, empty-range copy). Flagged two open items for the Architect rather than guessing: which charting package to add (none confirmed present), and which file-save/share mechanism to use for CSV (may or may not overlap with S-059's `share_plus` addition depending on shipping order). Explicitly scoped M-68 (S-037's richer area/line trend + period-over-period delta badges) OUT of this slice per task instruction, while flagging likely implementation-overlap for whoever picks up M-68 next as a dependency/ordering note. Out of scope: web changes, new backend work (verified not needed), revenue/payment analytics, admin analytics product, M-68's own scope. Depends on S-033 (Accepted, reference contract) and S-031 (existing mobile dashboard shell); non-blocking overlap noted with S-058/S-059 (same screen file). Status: Draft. Technical specification left as template for Architect. |
| 2026-08-18 | Architect | Technical specification: confirmed **no new backend endpoint/schema** (read `dashboard_api.dart` line-by-line: both `GET /dashboard/merchant/{business_id}` with `range` and `GET .../reviews.csv` with `range` are already fully generated, per S-033's Accepted contract) — this slice is `DashboardRepository.merchantStats` forwarding `range` (currently omitted) + a new `reviewsCsv` method, plus screen-level UI. Confirmed AC 4 (AI disclaimer) needs **no code change** — read `ai_insights_panel.dart` in full; it already carries the required suggestion/degraded copy from S-031, no gap exists (per PM's explicit instruction to verify rather than assume). **Charting package: `fl_chart`** (`^1.1.1`, pin latest at implementation) — the de facto maintained standard, pure-Dart, no native platform channel, covers both the volume bar/line chart (AC 1) and a new small `rating_distribution_chart.dart` widget for the 1-5 star mix (AC 2) with a single dependency; confirmed `SentimentBreakdown` is the wrong reuse target for AC 2 (positive/neutral/negative shape, not 1-5 stars) so a new small widget is added instead, `SentimentBreakdown` left untouched. **CSV mechanism: reuse `share_plus` (already added in S-059), no new package** — confirmed by reading `share_plus_platform_interface-7.2.0`'s `ShareParams` that it supports `files: List<XFile>?` alongside `text`, so the CSV bytes can go straight through `SharePlus.instance.share(ShareParams(files: [XFile.fromData(...)]))`, no `path_provider`/temp-file write needed. Flagged a codegen risk for Builder: the generated CSV client method returns `Response<JsonObject>` (not a typed CSV/string), reasoned through how built_value's `JsonObject` pass-through likely surfaces the raw CSV text via `.value`, but marked this unverified end-to-end (no running app in this review) with a concrete fallback (raw `Dio` call bypassing the one generated method) if the reasoning doesn't hold. RBAC matrix confirmed unchanged from S-033 (customer 403, merchant-owner 200, merchant-other 403, admin 200) — no new server-side check, no new client-side bypass. Data model impact: **None**, confirmed by grep against `dashboard_stats.dart`. Cache: no Redis change; range changes are live refetches, not stale client-side filtering. Frontend section names every new/modified file (`merchant_dashboard_screen.dart` modified, new `rating_distribution_chart.dart`, `dashboard_repository.dart` modified, `pubspec.yaml` +`fl_chart`), a mermaid flow for load/range-change/CSV-export, and flagged the M-68 overlap as a non-blocking ordering note (not scoped in). No ADR — new package, not a new integration/auth/schema pattern (same bar as S-059's `qr_flutter`/`share_plus`). Risks: `fl_chart` version churn (Builder to pin+verify at implementation time, not trust this spec's illustrative version), CSV unwrapping needs empirical Builder verification, tiles intentionally stay all-time (not range-filtered) matching S-033's own precedent. Architect checklist complete. **Status: Draft → Specified.** Builder may proceed. |
| 2026-08-18 | Builder | Implemented per spec. `dashboard_repository.dart`: `merchantStats` now forwards `range`; new `reviewsCsv` unwraps the generated `Response<JsonObject>` via `.value`. New `review_volume_chart.dart`/`rating_distribution_chart.dart` (`fl_chart` `BarChart`, empty-state copy). `merchant_dashboard_screen.dart`: `SegmentedButton<String>` range selector (live refetch), reply-rate tile (null → "No reviews in this range", never 0%), CSV export button wired to `SharePlus.instance.share(ShareParams(files: [XFile.fromData(...)]))`. Confirmed `fl_chart: ^1.2.0` (current stable, not the spec's illustrative `^1.1.1`) resolves cleanly. Also found and fixed a real narrow-screen overflow: the pre-existing S-059 "Edit business"/"Share review link" `Row` had no wrap behavior — changed to `Wrap`. `flutter analyze` 0 issues, full suite green pre-Tester. |
| 2026-08-18 | Tester | All 8 AC verified Pass. Added 10 widget tests to `merchant_dashboard_screen_test.dart` (range-selector refetch via a new `_RecordingDashboardRepository` fixture, chart populated/empty states, reply-rate null-vs-percent, CSV export happy/busy/error paths via a `_FakeSharePlatform` fixture using `share_plus`'s own documented testing seam). `flutter analyze` 0 issues, `flutter test` 210/210 (200 pre-existing + 10 new, 0 regressions). **Real bug found and fixed:** `XFile.fromData`'s `name:` param is documented as ignored on non-web platforms (`cross_file`'s `io` implementation) — the shared CSV would have had no filename on a real device; fixed via `ShareParams.fileNameOverrides`, `share_plus`'s documented mechanism for this exact case. Test plan/report: `TP-S-060-mobile-dashboard-analytics.md`, `TR-S-060-mobile-dashboard-analytics.md`. Recommendation: Ship, `implemented` (no deferral on any of the 8 AC). |
| 2026-08-18 | PM | Reviewed the Tester's report — all 8 AC Pass, no deferral, `implemented` adopted for M-61. `README.md` §12 M-61 row set to `implemented`, rollup corrected (`implemented` 51 · `partial` 3 · `unimplemented` 19 · `n/a` 6 · `future` 1 · total 80), Tier 3 roadmap row annotated with M-61 done. §8 Frontend guide (Mobile client section) documents the new `fl_chart` and `share_plus`-file-sharing conventions for reuse by future slices (e.g. M-68's trend/delta work should reuse `fl_chart`, not add a second charting package). §14/§16 updated. DoD checklist complete. **Status: Specified → Accepted.** |
