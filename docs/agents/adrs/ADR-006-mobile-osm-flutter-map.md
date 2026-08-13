# ADR-006: Mobile results map — flutter_map + OpenStreetMap tiles

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-13 |
| **Slice** | S-028 |

---

## Context

Web search and business profiles render maps with Leaflet + OpenStreetMap tiles (`GET /api/v1/maps/config` returns `provider: osm` and a tile URL). Mobile P1 (M-22, M-31) needs the same capability. Google Maps would break OSM parity, require an API key, and contradict README §6 (“not Google Maps”).

## Decision

1. Use **`flutter_map`** + **`latlong2`** for Explore results pins and the detail map pin.
2. Load the tile template from **`GET /api/v1/maps/config`**. If that call fails, fall back to `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
3. Set `userAgentPackageName` to the Android application id (`com.merchanthub.merchanthub_mobile`) so OSM tile use is identifiable.
4. Pass **device GPS** (`geolocator`, behind `LocationService`) as `lat` / `lng` / `radius_km` on **`GET /api/v1/search/businesses`**. Do not call `POST /maps/nearby` for this slice (search already implements radius).
5. Detail pins use **stored** `latitude` / `longitude` on `BusinessResponse`. Do not geocode on open (`GET /maps/geocode` stays a merchant-form web action).

## Consequences

### Positive

- Same map provider as web; no Google key in the mobile client.
- Tile URL stays server-configurable.
- Location and maps are mockable in widget tests.

### Negative / tradeoffs

- OSM raster tiles (not a native SDK). Acceptable for P1 pin browsing.
- Device location needs Android (and later iOS) permission strings.
- `flutter_map` tile loads can keep `pumpAndSettle` busy in tests — map assertions use `pump` / keys, not unbounded settle.

### Follow-ups

- If `/maps/config` ever switches providers, only `OsmMapView` / config parsing should change.
- iOS `NSLocationWhenInUseUsageDescription` when an `ios/` runner is added.

---

## Alternatives considered

1. **Google Maps Flutter plugin.** Rejected: keys, TOS, and web OSM mismatch.
2. **Static Nominatim/OSM image URL only.** Rejected: no pan/zoom, poor pin interaction (M-22).
3. **`POST /maps/nearby` instead of search lat/lng.** Rejected: would drop `q` / city / category / sort; search already does Haversine when lat/lng are present.
