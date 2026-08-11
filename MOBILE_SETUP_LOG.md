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

## Resumed session — timeout fix verified server-side, UI check handed to user (2026-08-11)

Restarted both processes to complete the deferred re-verification:
- Backend: `uvicorn app.main:app --host 127.0.0.1 --port 8000` — up, connected to the
  Railway DB via `backend/.env`.
- Flutter: `flutter run -d web-server --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8000`
  — served at `http://localhost:5000`.

**Network-level confirmation the fix works:** timed the two calls the login→list flow
makes, straight against the backend with `curl`:
- `POST /api/v1/auth/login` → `200` in ~10.6s
- `GET /api/v1/search/businesses?page=1&page_size=20` (the exact endpoint that previously
  tripped the old 10s timeout) → `200` in ~12.1s

Both are comfortably under the new 30s `receiveTimeout` in `api_client.dart`, and both
returned real data from the live DB. This confirms the fix at the layer that actually
matters (request duration vs. configured timeout) without depending on the UI.

**UI-level check not completed by me:** the Browser pane could not render the app to
verify visually — same limitation as the first pass (`ANDROID_APP_STRATEGY.md`-era
spike verification). `computer{screenshot}` fails with "the Browser pane is not
displayed, so the page is not compositing frames," and without a painted frame Flutter
never builds its semantics tree, so `read_page`/`get_page_text` see an empty DOM even
though network traffic (module loads, fonts) shows the app booted fine. Tried: fronting
the tab, resizing the viewport, clicking the `flt-semantics-placeholder` via dispatched
`MouseEvent`, waiting after each step — got as far as the placeholder responding (a lone
`textbox` ref appeared, likely the engine's hidden text-measurement input) but the real
login form never surfaced in the accessibility tree.

**Handed to user:** asked them to open `http://localhost:5000` themselves, log in as
`customer@example.com` / `customer123`, and confirm the business list renders without
the old timeout error — both servers were left running for this.

**Confirmed by user:** "yes i see busines loades" — login → business list round trip
works end-to-end with the 30s timeout fix. **Task #12 closed; the spike is fully
verified, both server-side and UI-side.**

Both local processes (`uvicorn` PID 14816, Flutter `dartvm` PID 13088) stopped
immediately after, per the standing note below — neither is holding a connection to the
production Railway DB anymore.

## Phase 2 — OpenAPI-generated Dart client (2026-08-11)

Replaced the hand-written DTOs (`token_response.dart`, `user.dart`, `business.dart`) and
raw Dio calls in the repositories with a generated client, per `ANDROID_APP_STRATEGY.md`
phase 2 ("Wire OpenAPI codegen; document API_BASE_URL flavors in README").

**Tooling decision:** the best-supported Dart target is `openapi-generator-cli`'s `dart-dio`
generator, but it needs Java, which wasn't installed. Rather than fight Windows admin/UAC
again (see the Postgres saga above), used **portable, no-installer** downloads — same
pattern as the Flutter SDK itself:
- Eclipse Temurin JRE 21 (`.zip`, ~49MB) from `github.com/adoptium/temurin21-binaries`,
  extracted to `C:\src\jre`.
- `openapi-generator-cli-7.14.0.jar` (~29MB) from Maven Central, saved to
  `C:\src\openapi-generator\`.

Both downloads were confirmed with the user first (filename/source/size) before fetching.
The alternative considered was `swagger_dart_code_generator` (pure Dart, no Java, 55k
weekly downloads) — rejected because it only targets Chopper, not Dio, which would have
meant rewriting the already-verified `AuthInterceptor` refresh logic onto a different HTTP
stack for no functional gain.

**Generation:**
```
python -c "... fastapi.openapi.utils.get_openapi(..., openapi_version='3.0.3') ..." > mobile/openapi.json
java -jar openapi-generator-cli-7.14.0.jar generate -i mobile/openapi.json -g dart-dio \
  -o mobile/packages/merchanthub_api --additional-properties=... serializationLibrary=built_value
```
The generator output is a standalone pub package (own `pubspec.yaml`), so it was moved to
`mobile/packages/merchanthub_api/` (sibling package) rather than left under `lib/generated/`
(which would nest one package's `lib/` inside another's), and wired into `mobile/pubspec.yaml`
via `path: packages/merchanthub_api`. It's **committed, not gitignored** — regenerating
needs Java, but building the app shouldn't.

**Bug found and fixed — blank optional query params:** `mobile/openapi.json`'s per-field
schemas came out as Pydantic v2's 3.1-style `anyOf: [type, null]` even after forcing
`openapi_version="3.0.3"` (that setting only stamps the top-level version string, it doesn't
rewrite nested schemas). `openapi-generator`'s `dart-dio` null-guard logic only skips a query
param when it has a literal default value (`page: int = 1` → guarded); params typed
`Optional[X] = None` (`min_rating`, `sentiment`, `lat`, `lng`) got no guard at all, so the
generated client always sent them as `''` when unset — which 422'd for the non-string types
before the request even reached the search handler. Fixed both layers:
1. `mobile/scripts/generate_api_client.py` (and the one-off generation above) now rewrites
   `anyOf: [type, null]` → `{type, nullable: true}` before generating — proper OAS 3.0, not
   a 3.1 shape wearing a 3.0 label. Didn't change the generator's behavior on its own, but is
   correct hygiene for `mobile/openapi.json` as a shared contract regardless.
2. `backend/app/routers/search.py`: added `OptionalFloatQuery`/`OptionalSentimentQuery`
   (`Annotated[X | None, BeforeValidator(_blank_to_none)]`) for `min_rating`, `sentiment`,
   `lat`, `lng` — treats `''` as absent, matching what the existing `if min_rating:` /
   `if sentiment:` filters below already assumed. `q`/`city`/`category` didn't need this —
   they're `str | None`, and `''` is already a valid string there.

Backend `tests/` search suite (4 tests) still passes after the change.

**Verified live**, end-to-end, via the Browser pane (semantics tree loaded this time — see
below on why it worked here but not for the earlier timeout re-check): filled the real login
form (`customer@example.com` / `customer123`) with `computer{type}` (had to switch from
`form_input` — it sets the DOM `<input>` value directly, which doesn't reach Flutter's
`TextEditingController` in web-canvas mode; real synthetic keystrokes via `computer{type}` do),
submitted, and confirmed via `read_network_requests`:
- `POST /api/v1/auth/login` → `200`
- `GET /api/v1/auth/me` → `200`
- `GET /api/v1/search/businesses?...` → `200` (was `422` before the fix above)

`read_page` then showed 10 real businesses rendered (names, cities, ratings, review counts) —
confirms the generated `built_value` deserialization round-trips correctly against live data,
not just that the request succeeded.

`flutter analyze` (3 pre-existing intentional infos only, generated package excluded via
`analysis_options.yaml`) and `flutter test` (1/1 passing, fake repo updated to build a
generated `UserResponse` via its builder) both clean.

Regeneration workflow for future backend changes is `mobile/scripts/generate_api_client.py`,
documented in `README.md` under "Mobile client (Flutter)".

## Before continuing to phase 3 (real feature screens)

- Provision a **separate, dedicated dev Postgres** (not this production one) before any write-path testing (reviews, favorites, registration) — flagged above, still applies.
- Keep stopping the local backend and Flutter dev server between sessions when not actively using them, since both connect through to production data while running.

## Phase 3 — GitHub Actions emulator CI + mandatory TOTP MFA (2026-08-11)

No local Windows Android emulator (needs Hyper-V/WHPX: admin rights + reboot, declined).
Instead: `.github/workflows/mobile-emulator-check.yml`, a free/open-source/non-interactive
alternative — `reactivecircus/android-emulator-runner` boots a real KVM-accelerated emulator on
GitHub's own Linux runners, against a throwaway Postgres/Redis + backend stood up in the same
job (never the Railway DB), running `mobile/integration_test/app_test.dart` (login →
business-list) and uploading a screenshot artifact. Raw Actions job logs and artifact downloads
both need repo-admin auth this environment doesn't have (`403` on both, even for a public repo,
even in the signed-out web UI) — diagnosis leaned on local reproduction and on writing
`backend.log` to `$GITHUB_STEP_SUMMARY` on failure, which *does* render on the public run
overview page.

Three real bugs found and fixed via that loop, each confirmed by the run progressing further
than the last:

1. **Backend crashed on every bare-runner boot** (`backend/app/config.py`): `storage_local_path`
   defaulted to the absolute `/app/uploads`, correct only because `docker-compose.yml` sets
   `WORKDIR /app` in the container (and overrides the env var explicitly anyway). Outside Docker,
   `main.py`'s module-level `uploads_path.mkdir()` tried to create `/app` at the filesystem root
   and hit `PermissionError` before uvicorn could bind — the actual cause of both early "Start
   backend" failures, unrelated to the emulator. Fixed by changing the default to the relative
   `./uploads`, matching what `.env.example` already documented; Docker is unaffected since it
   sets the env var explicitly.
2. **`flutter drive` invocation mangled**: `reactivecircus/android-emulator-runner`'s `script:`
   input didn't survive a multi-line YAML block scalar with `\` line continuations — it invoked
   `flutter drive` with a literal `\` as the `--target` value. Fixed by single-lining the command.
3. **Gradle build failure**: `flutter_secure_storage` requires `compileSdk 37`; the project's
   `compileSdk = flutter.compileSdkVersion` resolved to `36` on the current stable Flutter
   channel. Fixed with a pinned `compileSdk = 37` in `mobile/android/app/build.gradle.kts`.

After all three, the emulator run reached the actual test — which then failed for a real reason:
`backend/scripts/seed.py` (from an unrelated, concurrently-landed slice, S-020) now enables TOTP
for every demo account, and `POST /auth/login` no longer returns tokens directly for a TOTP
account (`LoginResult.mfa_required` + `mfa_token` instead). The mobile client, built before S-020
landed, had zero MFA handling — meaning it couldn't complete login at all against current `main`,
in CI or for real. Closed the gap rather than bypassing it:

- Regenerated `mobile/packages/merchanthub_api/` (`mobile/scripts/generate_api_client.py`)
  against the current backend schema — pulls in `LoginResult`, `MfaTokenRequest`,
  `MfaTotpCodeRequest`, `TotpSetupResponse`, and the `totpSetup`/`totpConfirm`/`totpVerify`
  `AuthenticationApi` methods.
- `lib/features/auth/login_screen.dart` now mirrors `frontend/src/components/LoginForm.tsx`'s
  three-step flow (credentials → enroll-with-QR-or-verify-code); `auth_repository.dart` /
  `auth_provider.dart` reworked so `submitCredentials` returns the raw `LoginResult` and only
  `totpConfirm`/`totpVerify` resolve `AuthController`'s state to a session. Added `flutter_svg`
  to render the enrollment QR.
- `mobile/integration_test/app_test.dart` now completes the real verify step, computing a live
  TOTP code from the seeded demo secret (`backend/app/services/mfa.py`'s
  `DEMO_TOTP_SECRET = "JBSWY3DPEHPK3PXP"`) via the `otp` package (SHA1/30s/6-digit, `isGoogle:
  true` for standard base32 decode — matches `pyotp`'s defaults).

**Local verification:** `flutter analyze` clean, `flutter test` passes (widget test drives the
real `LoginScreen` → `AuthController` → fake-repository path through both the credentials step
and the TOTP-verify step), and `flutter build web --release` compiles cleanly. Did *not* get a
live browser-driven walkthrough this round — the Flutter-web debug (DDC) dev loop stalled
mid-boot in the Browser pane tooling (unrelated flakiness: navigation intermittently denied,
DDC's ~850-module load never reached `_flutter.loader.load()`), and a `--release` static-server
attempt hit the same navigation flakiness. Given the target platform is Android, not web, and the
emulator CI is the environment that actually caught all three infra bugs above, deferred to that
as the real verification rather than continuing to fight unrelated web-tooling issues.

## Deferred (not part of this pass)

- Android Studio + SDK + emulator/physical-device setup for a real *local* APK build (the CI
  emulator now covers automated verification; this would be for interactive manual testing).
- Reviews/favorites screens, merchant screens, Play Store release pipeline (strategy doc phases
  4-5).
- `mobile/CLAUDE.md` + matching `.cursor/rules/mobile-flutter.mdc`, and registration in `scripts/check_agent_config_sync.py` — per the repo's enforced doc-sync convention. Not yet done; the sync checker doesn't currently require it (`scripts/check_agent_config_sync.py --range` confirmed no failure), so it's not blocking, but should land before mobile work gets deep enough that a dedicated builder rule pays for itself.
