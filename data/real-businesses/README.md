# Real business reference data

Real-world local business listings collected via web search for demo/seed purposes
(restaurants, cafes, salons, auto repair shops, hospitals/urgent care). Wired into
the DB through [`backend/scripts/seed_us.py`](../../backend/scripts/seed_us.py),
called from [`backend/scripts/seed.py`](../../backend/scripts/seed.py) after the
Chennai seed.

## Coverage

| File | City |
|---|---|
| [`fremont-ca.json`](fremont-ca.json) | Fremont, CA |
| [`union-city-ca.json`](union-city-ca.json) | Union City, CA |
| [`brandon-fl.json`](brandon-fl.json) | Brandon, FL |
| [`dallas-tx.json`](dallas-tx.json) | Dallas, TX |

Categories per city: `restaurant`, `cafe`, `salon`, `auto_repair`, `hospital`.

## Schema

Each file is `{ city, collected_date, businesses: [...] }`. Each business entry:

```json
{
  "name": "",
  "category": "",
  "address": "",
  "city": "",
  "state": "",
  "zip": "",
  "phone": "",
  "website": "",
  "hours": "",
  "rating": 0.0,
  "review_count": 0,
  "maps_url": "",
  "photo_reference_url": "",
  "sources": []
}
```

Fields that couldn't be verified via search are `null` rather than guessed.

## Important limitations (read before using this data anywhere user-facing)

- **Ratings/review counts in JSON are not used for display.** Actual customer
  review text on Google/Yelp is copyrighted user content, so it was not scraped or
  reproduced. The seed writes original synthetic review blurbs (Chennai-style) and
  recalculates aggregates via `update_business_rating()`. Do not attribute invented
  text to real third-party reviewers.
- **No image files were downloaded.** `photo_reference_url` is ignored by the seed.
  Listings get licensed Unsplash stock photos by category instead of hotlinking
  Google/Yelp photos.
- **Data is a point-in-time snapshot** (see `collected_date`). Hours, phone numbers,
  and ratings drift — re-verify before relying on this for anything beyond local dev
  seed data.

## Using this data

Wired for local/demo seeding via `seed_us.py`. Resolution order:

1. [`backend/data/real-businesses/`](../../backend/data/real-businesses/) — **packaged in the backend Docker image** (required for Railway; keep in sync with this folder)
2. This directory (monorepo root)
3. `/data/real-businesses` (Compose mount in [`docker-compose.yml`](../../docker-compose.yml))

Upserts by slug (`name-city`), maps `zip` → `postal_code` and `hours` →
`business_hours={"raw": "..."}`, places pins at city-center lat/lng with slug
jitter, attaches Unsplash photos, and adds three synthetic reviews + mock
`AIAnalysis` per shop. Safe to re-run.
