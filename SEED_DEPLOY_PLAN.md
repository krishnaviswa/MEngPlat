# Plan: Decouple seeding from deploys (+ optional blue-green later)

**Status:** Phase 1–2 implemented (2026-08-10). Phases 3–5 not started.  
**Goal:** Stop every Railway/backend boot from re-upserting demo data, so deploys stay fast and scale. Optionally add blue-green later without dual-DB complexity first.

---

## Problem (current)

Backend start on Railway (`[backend/railway.json](backend/railway.json)`):

```text
alembic upgrade head → python scripts/seed.py → uvicorn
```

`[backend/scripts/seed.py](backend/scripts/seed.py)` + Chennai/US upserts refresh ~60 businesses, reviews, photos, and ratings on **every** deploy. Idempotent ≠ cheap.

---



## Target outcomes

1. **Every deploy:** migrate schema + start API only (fast).
2. **Seed:** explicit / version-gated job — not on the request-critical boot path.
3. **Local Compose:** still easy to get demo data (opt-in or first-run).
4. **Later (optional):** blue-green **app** cutover on one DB; dual-DB swap only for disposable demo resets.

---



## Phase 1 — Stop seeding on every deploy (do this first)



### 1.1 Change Railway start command

**File:** `[backend/railway.json](backend/railway.json)`

**From:**

```sh
alembic upgrade head && (PYTHONPATH=/app python scripts/seed.py || echo 'WARNING: seed failed — starting API anyway') && uvicorn ...
```

**To:**

```sh
alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```



### 1.2 Keep Compose demo-friendly

**File:** `[docker-compose.yml](docker-compose.yml)`

- Keep seed in the **local** backend command override, **or** switch to env-gated seed (Phase 2) so local and Railway share one code path.
- Prefer one path: `SEED_MODE` (below) rather than “Railway never seeds / Compose always seeds” forever.



### 1.3 Document how to seed on Railway after deploy

**File:** `[README.md](README.md)` §10 / §1

- One-shot: Railway shell / one-off job:
  ```sh
  PYTHONPATH=/app SEED_MODE=force python scripts/seed.py
  ```
- Or: add a Railway “cron / one-shot” service later that only runs seed (Phase 3).



### 1.4 Acceptance

- [ ] Redeploy backend without running Chennai/US upsert in start logs.
- [ ] API healthy; existing DB data unchanged.
- [ ] Manual seed still works when invoked explicitly.

---



## Phase 2 — Version-gated seed (skip when already applied)



### 2.1 Add a seed marker table (Alembic migration)

New table, e.g. `seed_runs`:


| Column       | Type             | Notes                           |
| ------------ | ---------------- | ------------------------------- |
| `id`         | UUID PK          |                                 |
| `version`    | `varchar` unique | e.g. `2026-08-10-chennai-us-v1` |
| `applied_at` | timestamptz      |                                 |
| `notes`      | text nullable    | optional                        |


Bump `SEED_VERSION` constant in `[backend/scripts/seed.py](backend/scripts/seed.py)` whenever seed content meaningfully changes.

### 2.2 Seed modes via env


| `SEED_MODE`   | Behavior                                                      |
| ------------- | ------------------------------------------------------------- |
| `off`         | No-op (default on Railway production)                         |
| `if_empty`    | Seed only if no approved businesses (or no `seed_runs` row)   |
| `if_outdated` | Seed only if `seed_runs` missing current `SEED_VERSION`       |
| `force`       | Always run full upsert; then upsert marker to current version |


**Defaults suggestion:**

- Railway prod: `SEED_MODE=off` (or omit; treat missing as `off`)
- Docker Compose: `SEED_MODE=if_outdated` or `if_empty`
- Manual refresh: `SEED_MODE=force`



### 2.3 Wire [seed.py](http://seed.py)

At start of `seed()`:

1. Read `SEED_MODE` / `SEED_VERSION`.
2. If `off` → exit 0.
3. If `if_outdated` and marker == version → print “Seed skipped (version X)” → exit 0.
4. Else run existing `_seed_base` / `seed_chennai` / `seed_us`.
5. Insert/update `seed_runs` for current version; commit.



### 2.4 Tests

- Unit/integration: `SEED_MODE=off` does not create businesses.
- `if_outdated` second run is no-op.
- `force` refreshes and updates marker.
- Existing stats/favorites tests unchanged when DB already seeded in fixtures.



### 2.5 Acceptance

- [ ] Second seed with same version is near-instant no-op.
- [ ] Content change + version bump reapplies once.
- [ ] README §15 lists `SEED_MODE`, `SEED_VERSION`.

---



## Phase 3 — Optional seed job (not on web dyno)

Only if you want scheduled or button-click demo refresh:

1. Railway one-shot / cron service using same image.
2. Start command: `PYTHONPATH=/app SEED_MODE=force python scripts/seed.py` (or `if_outdated`).
3. Same `DATABASE_URL` as API.
4. Never attach public domain to the seed service.

---



## Phase 4 — Blue-green **apps**, one database (optional, later)

Use when you need zero-downtime **code** deploys — **not** to fix seed slowness (Phase 1–2 already did).

```text
Users → router → Blue (live) ─┐
                 Green (warm) ─┴→ same Postgres
```



### Rules

- Migrations: **expand → deploy → contract** (additive columns first).
- Both colors point at **one** `DATABASE_URL`.
- Do **not** run seed on green boot.
- Health check green → flip traffic → keep blue for rollback window.



### Railway-shaped steps (conceptual)

1. Deploy new revision as second replica / canary if platform supports it.
2. Run `alembic upgrade head` once (expand-only) before or as part of release.
3. Flip public traffic to new revision.
4. Roll back = point traffic to previous revision (DB still compatible).

---



## Phase 5 — Dual-database swap (optional, demo-only)

Use **only** for disposable “reset the whole demo world” — not every deploy.

```text
Live:    API_A → DB_A
Prep:    seed/migrate DB_B offline → API_B health checks
Cutover: flip DATABASE_URL (or DNS) to DB_B
Rollback: flip back to DB_A within N hours
```



### When to use

- You want a clean known-good demo snapshot without locking the live API during seed.
- You accept that writes on the old DB during prep are abandoned unless you freeze writes or replicate.



### When **not** to use

- Normal feature deploys (use Phase 1–2).
- Production with real user data (prefer one DB + expand/contract migrations).



### Cheaper alternative to dual DB

Keep a **Postgres snapshot / backup** of a known-good seeded DB and restore into a staging DB, or restore over a demo DB during a maintenance window — often simpler than maintaining DB_A/DB_B forever.

---



## Recommended apply order


| Order | Phase                                    | Effort  | Deploy impact                |
| ----- | ---------------------------------------- | ------- | ---------------------------- |
| 1     | Phase 1 — remove seed from Railway start | Small   | Immediate faster deploys     |
| 2     | Phase 2 — `SEED_MODE` + `seed_runs`      | Medium  | Safe re-runs, Compose parity |
| 3     | Phase 3 — one-shot seed job              | Small   | Ops convenience              |
| 4     | Phase 4 — blue-green apps                | Larger  | Zero-downtime code           |
| 5     | Phase 5 — dual DB swap                   | Largest | Demo reset only              |


**Do not start with Phase 5** to fix slow deploys.

---



## Files likely touched (when implementing)


| File                                                   | Change                                       |
| ------------------------------------------------------ | -------------------------------------------- |
| `[backend/railway.json](backend/railway.json)`         | Drop `seed.py` from `startCommand`           |
| `[docker-compose.yml](docker-compose.yml)`             | Pass `SEED_MODE`                             |
| `[backend/scripts/seed.py](backend/scripts/seed.py)`   | Gate + version marker write                  |
| `[backend/app/models/](backend/app/models/)` + Alembic | `seed_runs` table                            |
| `[backend/app/config.py](backend/app/config.py)`       | `SEED_MODE` / `SEED_VERSION` settings        |
| `[backend/tests/](backend/tests/)`                     | Mode / skip / force cases                    |
| `[README.md](README.md)` §1, §10, §15                  | Deploy + env docs (project single prose doc) |


---



## Out of scope for this plan

- Changing homepage / frontend.
- Moving uploads off ephemeral disk (separate storage issue).
- Full multi-region active-active databases.

---



## Done definition

- Production deploys no longer block on Chennai/US upsert.
- Demo data can still be created/refreshed deliberately.
- Re-seed is O(1) skip when version unchanged.
- Blue-green / dual-DB documented as optional follow-ons, not required for the seed fix.

