# Flutter mobile client — setup & spike log

Working log for the Flutter mobile client build-out described in
[`ANDROID_APP_STRATEGY.md`](ANDROID_APP_STRATEGY.md). Records what was decided, what's
done, and exact commands/credentials used, so this can be picked back up in a later
session without re-deriving context.

> **Local dev credentials only.** Everything in this file is for a developer's own
> machine (local Postgres, no network exposure beyond `localhost`). None of it is a
> production secret — same spirit as the `dev-secret-key-change-in-production` default
> already committed in `backend/.env.example`. Don't reuse these values for anything
> beyond local dev, and don't copy this pattern for real credentials.

## Decisions made

- **Dev/verification loop: Flutter Web (Chrome/`web-server`), not an Android emulator or
  physical phone.** Avoids Hyper-V/virtualization setup (admin + reboot) and AVD/phone
  setup for the first pass. Android Studio + SDK + emulator/device is a deferred, separate
  step for when a real APK build is needed.
- **Editor: Cursor** (already installed). `Dart-Code.flutter` extension install hit a
  transient file-lock error mid-session; not blocking since all verification runs from
  the terminal (`flutter analyze` / `flutter test` / `flutter run`) regardless of editor
  extensions.
- **Packages:** `dio` (interceptor chain for auth refresh), `flutter_secure_storage`
  (token storage), `flutter_riverpod` (state mgmt, no codegen yet), `go_router`
  (auth-guarded routing). Hand-written Dart models for the 3 spike DTOs — OpenAPI codegen
  deferred to strategy-doc phase 2.
- **Local backend, no Docker:** Docker itself isn't installed on this machine either.
  Redis is optional for this backend (every cache/blocklist call in
  `backend/app/services/cache.py` fails open by design), so only Postgres is a hard
  requirement. Installing Postgres natively (no virtualization needed) was chosen over
  Docker Desktop (which would need WSL2).

## Steps completed

1. **Flutter SDK** — installed via `git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter`, added `C:\src\flutter\bin` to the user `PATH`. Verified: Flutter 3.44.9, Dart 3.12.2, Chrome device detected. `flutter doctor -v` is clean except Android toolchain (expected, deferred) and Visual Studio/Windows-desktop (not needed).
2. **`mobile/` scaffolded** — `flutter create mobile --org com.merchanthub --project-name merchanthub_mobile --platforms=web,android`, then `flutter pub add dio flutter_secure_storage flutter_riverpod go_router`.
3. **Local CORS** — added `http://localhost:5000` to `CORS_ORIGINS` in `docker-compose.yml` (Flutter web dev port), alongside the existing `http://localhost:3000` for the Next.js frontend.
4. **Core layer** (`mobile/lib/core/`) — `config/app_config.dart` (API base URL via `--dart-define`), `network/api_client.dart` (two `Dio` instances: auth-free + interceptor-attached), `network/auth_interceptor.dart` (refresh-on-401-once, shared in-flight refresh, `refresh_token` sent as a **query param** per the real backend contract), `storage/token_storage.dart` (`flutter_secure_storage` wrapper), `models/{user,token_response,business}.dart` (hand-written, matching `backend/app/schemas/__init__.py` field-for-field).
5. **Auth feature** (`mobile/lib/features/auth/`) — repository, Riverpod `AsyncNotifier`, `LoginScreen`.
6. **Businesses feature** (`mobile/lib/features/businesses/`) — repository (`GET /search/businesses`), provider, `BusinessListScreen`.
7. **Routing** — `go_router` with a `redirect` auth guard bridged to Riverpod via a `ChangeNotifier` that listens to the auth provider.
8. **Verification, code level** — `flutter analyze`: clean (3 harmless style infos left intentionally). `flutter test`: `LoginScreen` widget test passes against a faked repository.
9. **Verification, running app** — `flutter run -d web-server --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8000`, opened via the Browser pane at `http://localhost:5000`. Confirmed via screenshot + `read_network_requests` that the login form renders, accepts input, and on submit correctly fires `POST http://localhost:8000/api/v1/auth/login` (failed with `ERR_CONNECTION_REFUSED` since no backend was up yet — expected, and the error surfaced cleanly in the UI instead of crashing).

## Abandoned: local Postgres install

Docker isn't installed and this session has no admin rights, so Claude could not run
installers requiring UAC elevation itself.

**What happened:**
- `winget install --id PostgreSQL.PostgreSQL.17 -e --silent ...` (Claude, non-elevated) → failed twice: first with a UAC cancellation, second attempt got further (wrote binaries, created the `postgresql-x64-17` service) but `initdb` failed because the data directory had leftover files from the first cancelled attempt. Service ended up `Running` with an unknown, auto-generated superuser password (written to a temp pwfile that was already deleted by the time this was noticed).
- Claude attempted to reset the password by temporarily setting `pg_hba.conf` auth to `trust` — **blocked by the coding agent's own safety classifier** (correctly: weakening DB auth, even temporarily, is a security-config change Claude shouldn't make itself).
- User ran an elevated uninstall/reinstall with a specified password (`merchanthub123`); winget's uninstall only deregistered the package without actually removing the running service, so the reinstall no-opped ("already installed, no upgrade available") and the password never actually got set.
- Rather than keep fighting winget/UAC, the user opted to use a hosted Postgres instead (see below) and cleaned up the broken local install (service uninstalled via the dedicated `uninstall-postgresql.exe`, `C:\Program Files\PostgreSQL\17` removed, winget package record cleared, temp installer dirs and `install-postgresql.log` deleted). Confirmed clean: `winget uninstall --id PostgreSQL.PostgreSQL.17` returned "No installed package found matching input criteria."

No local Postgres credentials exist as a result — this path was fully abandoned.

## Backend now live: hosted Railway Postgres

The user provisioned a Postgres instance and gave Claude its connection string directly
in chat. **This connection string is a real, live, remotely-reachable secret** (unlike
the abandoned local-only password above) — it was written **only** to `backend/.env`
(confirmed git-ignored via the bare `.env` pattern in root `.gitignore`), and is
deliberately **not** reproduced in this file or anywhere else committed.

**Incident: this turned out to be the production/deployed database, not a throwaway one.**
Claude ran, before realizing this:
- `alembic upgrade head` — a no-op (`alembic current` showed it was already at head, before and after — no schema change applied).
- `python scripts/seed.py` with `SEED_MODE=force` (copied verbatim from `.env.example`'s default without adjusting for this being a live DB) — this bypassed the version-gate the team built specifically to avoid reseeding on every boot (see `SEED_DEPLOY_PLAN.md`). It force-refreshed all 60 seeded demo businesses (ratings/AI summaries recalculated) and, for at least one business, deleted and re-inserted its photo rows with the script's default demo image URLs. It also inserted a new `seed_runs` log row.

The `created=0, refreshed=N` counts in the seed output were the tell — a genuinely fresh
database would show `created=N, refreshed=0`.

**Impact assessed and confirmed with the user before continuing further:** everything
touched was the demo/seed dataset the script itself owns (Chennai + US demo businesses),
not real user accounts, reviews, or uploads. The specific next verification step (login +
fetch business list) is read-only against Postgres — `POST /auth/login` and
`GET /search/businesses` don't write to the DB, and logout's token-blocklist write goes to
Redis (not reachable here, fails open, no write anywhere). Residual risk flagged to the
user: a second local backend process adds connection-pool pressure to a possibly
connection-constrained shared Postgres while it's running, and any *future* write-testing
(reviews/favorites/registration) against this same DB would start mixing test data into
production — recommended a dedicated throwaway DB before going further than login/list.

**Decision: proceed with read-only verification only** (login + business list) against
this database; do not use it for write-path testing in later phases.

## Spike complete — full end-to-end verification passed

1. ~~Local Postgres~~ — abandoned, see above. Using hosted Railway Postgres instead.
2. `backend/.env` written with the Railway `DATABASE_URL` (asyncpg driver), `AI_PROVIDER=mock`, `CORS_ORIGINS` including `http://localhost:5000`. Not committed (git-ignored).
3. `alembic upgrade head` — done, no-op (already at head).
4. `python scripts/seed.py` — done (see incident above); demo accounts confirmed present: `customer@example.com` / `customer123`, `merchant@example.com` / `merchant123`, `admin@merchanthub.ai` / `admin12345`.
5. `uvicorn app.main:app --host 127.0.0.1 --port 8000` started locally against this DB. Bound to `127.0.0.1` specifically (not `0.0.0.0`) — the coding agent's safety classifier correctly blocked an all-interfaces bind while pointed at a production database; localhost-only is also all that's actually needed here. `GET /health` confirmed `{"status":"healthy", ...}`.
6. Automated Browser-pane verification (network-request inspection, screenshot) hit a dead end this session: the pane wasn't visually displayed client-side, which appears to have stalled Flutter's CanvasKit renderer's paint-driven semantics tree (no accessibility DOM ever populated, screenshots timed out). Flutter web no longer supports forcing the HTML renderer (`--web-renderer` flag removed in this version) as a workaround.
7. **User manually verified instead**, opening `http://localhost:5000` directly and logging in as `customer@example.com` / `customer123` — confirmed working end-to-end: real login, real JWT issuance, real business list rendered from the actual Railway Postgres data.

**Spike goal achieved**: Flutter app ↔ FastAPI backend ↔ real Postgres, full round trip, proven.

## Post-verification fix: Dio timeout

After the E2E login worked, a follow-up request (`GET /search/businesses`) hit a Dio
`connectTimeout`/`receiveTimeout` error in the app. Backend logs showed why: the query
itself is fast, but each of its 3 sequential round trips to the remote Railway Postgres
(businesses → business_categories → categories, plus BEGIN/COMMIT) costs several hundred
ms to a few seconds over the public internet — ~9.5s total, confirmed reproducible via
direct `curl` timing. **Not a code bug** — purely an artifact of running the backend
locally against a *remote* DB instead of a co-located one (Docker Compose locally, or
production on Railway's own network, would see near-zero latency for the same code).
Fixed by raising `receiveTimeout` from 10s → 30s in
`mobile/lib/core/network/api_client.dart` (with a comment explaining why, so it isn't
mistaken for a real requirement later). `connectTimeout` left at 10s (TCP handshake, not
the slow part).

## Session paused here (2026-08-11)

Stopped by user request before the timeout fix could be re-verified in the running app.
Current state:
- **Both local processes are stopped.** The `uvicorn` backend (port 8000) had already
  exited on its own by the time we checked; the Flutter dev server (port 5000, `dartvm`
  process) was stopped deliberately. Neither is holding a connection to the production
  Railway DB anymore.
- `backend/.env` still has the live Railway `DATABASE_URL` in it (git-ignored, not
  committed) — that's what a future `uvicorn app.main:app --host 127.0.0.1 --port 8000`
  run from `backend/` (with `PYTHONPATH` set to `backend/`) will reconnect to.
- `mobile/lib/core/network/api_client.dart` has the 30s timeout fix in place but **not
  yet re-verified live** — that's the immediate next step when resuming.

**To resume:** start the backend (`PYTHONPATH=<repo>/backend .venv/Scripts/python.exe -m
uvicorn app.main:app --host 127.0.0.1 --port 8000`), start the Flutter app (`flutter run
-d web-server --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8000`), and
log in as `customer@example.com` / `customer123` at `http://localhost:5000` — confirm the
business list now renders without the earlier timeout error.

## Before continuing to phase 3 (real feature screens)

- Provision a **separate, dedicated dev Postgres** (not this production one) before any write-path testing (reviews, favorites, registration) — flagged above, still applies.
- Keep stopping the local backend and Flutter dev server between sessions when not actively using them, since both connect through to production data while running.

## Deferred (not part of this pass)

- Android Studio + SDK + emulator/physical-device setup for a real APK build.
- OpenAPI-generated Dart models/client (strategy doc phase 2).
- Reviews/favorites screens, merchant screens, CI/Play Store pipeline (strategy doc phases 3-5).
- `mobile/CLAUDE.md` + matching `.cursor/rules/mobile-flutter.mdc`, registration in `scripts/check_agent_config_sync.py`, and a `README.md` mention — per the repo's enforced doc-sync convention, worth doing once the spike is committed, not blocking the spike itself.
