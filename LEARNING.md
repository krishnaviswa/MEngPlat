# Learning: File Types in This Repo

A plain-language reference for what each file extension in MerchantHub AI (MEngPlat) is,
who uses it, and how to safely open or run it. Written for a non-technical read-through —
see `README.md` for the real technical architecture.

## 1. File extensions, one by one

**`.tsx`** — A React web page or UI component written in TypeScript. **Frontend.** Language: TypeScript + a bit of HTML-like markup (JSX). Talks to: the backend via API calls, and to other `.tsx`/`.ts` files that provide shared logic.

**`.ts`** — Plain TypeScript logic with no visual markup (config, helper functions, type definitions). **Frontend / config.** Language: TypeScript. Talks to: `.tsx` files that import it, and to build tools like `tailwind.config.ts`.

**`.py`** — A Python file: API routes, business logic, database models, or database migrations. **Backend / database.** Language: Python. Talks to: the PostgreSQL database (via SQLAlchemy), and to the frontend indirectly by serving API responses that `.tsx` files call.

**`.dart`** — A Flutter mobile-app file (screens, widgets, app logic). **Frontend (mobile).** Language: Dart. Talks to: the same backend API as the web frontend, just from the phone app instead of a browser.

**`.md`** — A Markdown document: README, architecture notes, agent workflow specs, runbooks. **Docs.** Language: plain text with light formatting. Talks to: nothing programmatically — it's for humans (and AI assistants) to read.

**`.json`** — Structured data/config: package lists, API schemas, settings. **Config / data.** Language: JSON (a simple data format, not a programming language). Talks to: whatever tool reads it — e.g., `package.json` tells Node.js which libraries the frontend needs.

**`.mdc`** — Cursor IDE's own rule files (the Cursor-editor twin of this project's `CLAUDE.md` files). **Config / docs.** Language: Markdown with special headers. Talks to: the Cursor AI editor only — kept in sync with `CLAUDE.md` by convention, not by code.

**`.png` / `.svg`** — Image files (screenshots, icons, logos). **Other (assets).** Not code. Talks to: `.tsx`/`.dart`/`.md` files that display them.

**`.yml` / `.yaml`** — Configuration written in YAML format: Docker Compose setup, CI pipelines, mobile analysis rules. **Config.** Language: YAML (data format). Talks to: the tool it configures (e.g., `docker-compose.yml` tells Docker which containers to start).

**`.xml`** — Android configuration files (part of the Flutter mobile app's Android wrapper). **Config (mobile).** Language: XML. Talks to: the Android build system.

**`.js`** — A small number of JavaScript config files (e.g., Jest test config, Next.js config). **Config.** Language: JavaScript. Talks to: the Node.js tools that read them at build/test time.

**`.kt` / `.kts`** — Kotlin files, used for Android-specific glue code and Gradle build scripts in the mobile app. **Backend of the mobile app / config.** Language: Kotlin. Talks to: the Android build system and the Dart code above it.

**`.properties` / `.ini`** — Simple `key=value` settings files (Android Gradle settings, Python's `alembic.ini` for database migrations). **Config.** Not a programming language. Talks to: the specific tool that owns it (Gradle, or Alembic for DB migrations).

**`.lock`** — An auto-generated file that pins exact versions of every dependency (e.g., `pubspec.lock` for the mobile app). **Config.** Not human-authored. Talks to: the package manager only — never edit by hand.

**`.example`** (e.g. `.env.example`) — A template showing what secret/config values a real `.env` file needs, without the real values. **Config.** Talks to: developers, as a copy-paste starting point.

**`.css`** — Styling rules (colors, spacing, fonts) for the web app. **Frontend.** Language: CSS. Talks to: the `.tsx` components it styles.

**`.html`** — A single static HTML page (the mobile app's web-build entry point). **Frontend.** Language: HTML. Talks to: the browser directly, and loads the compiled Dart/JS code.

**`.txt`** — Loose plain-text notes/checklists. **Docs.** Not code.

**No extension — `Dockerfile`** — Instructions for building a container image of the backend or frontend. **Config.** Language: Dockerfile syntax. Talks to: Docker, which uses it to package the app for deployment.

## 2. Can I open/run these myself?

| Extension | Double-click it? | Run it directly? | Warnings |
|---|---|---|---|
| `.tsx` / `.ts` | Opens as text in an editor (VS Code etc.) — no useful preview by double-clicking in File Explorer | Not on its own — it runs as part of the whole frontend via `npm run dev` | Needs Node.js installed; needs the rest of the project to make sense |
| `.py` | Opens as text | Yes, individually with `python file.py` — but most of these are meant to run as part of the FastAPI app via `uvicorn`, not standalone | Needs Python + the project's installed packages; some `.py` files are database migrations — running them directly changes the database |
| `.js` (config) | Opens as text | Some can run with `node file.js`, but these are config files read by other tools, not standalone programs | Needs Node.js |
| `.dart` | Opens as text | Only within a Flutter project, via `flutter run` | Needs the Flutter SDK |
| `.json` | Double-clicking often opens it in a browser or text editor showing raw data | Not runnable — it's data, not instructions | Editing by hand can break whatever tool depends on it (e.g. `package.json`) |
| `.yaml` / `.yml` | Opens as text, human-readable | Not runnable directly — read by tools like Docker Compose | Indentation matters a lot; a stray space can break it |
| `.md` | Double-click opens as plain text; GitHub/most editors render it nicely with headings and bullets | Not runnable | None — safest file type in the repo |
| `.css` | Opens as text | Not runnable alone | Only affects appearance if the matching `.tsx` file loads it |
| `.html` | Double-click opens it in your web browser and you'll see a page | Not "run" — just displayed | This one file expects compiled app code alongside it; opening it alone may look broken |
| `.png` / `.svg` | Double-click opens an image viewer | Not runnable | None |
| `.env.example` | Opens as text | Not runnable | Never put real passwords/keys in the checked-in version — copy it to `.env` first |

## 3. Logical groups

**Frontend (web)** — `frontend/src/app/globals.css`, `frontend/src/app/**/*.tsx`, `frontend/tailwind.config.ts`
This is the website users see in a browser: pages, buttons, forms. It calls the backend's API (`/api/v1/...`) to fetch or save data, and reads `globals.css`/Tailwind config to know how things should look.

**Frontend (mobile)** — `mobile/lib/**/*.dart`, `mobile/android/app/build.gradle.kts`, `mobile/web/index.html`
The Flutter phone app — same job as the website (customer/merchant/admin screens) but built for iOS/Android. It talks to the exact same backend API as the web frontend, so a business's data looks the same on both.

**Backend** — `backend/app/routers/*.py`, `backend/app/services/*.py`, `backend/app/models/*.py`
The FastAPI server: it receives requests from the web or mobile frontend, runs business logic (in `services/`, per this project's rules), and reads/writes the database via the models. It's the middleman between the apps and the data.

**Database / migrations** — `backend/alembic/versions/*.py`, `backend/alembic.ini`, `backend/app/models/*.py`
`models/*.py` describes the shape of the data (tables, columns) in Python code; `alembic/versions/*.py` are step-by-step scripts that apply those shape changes to the real PostgreSQL database over time, run via the `alembic` command — not by double-clicking.

**Config / infrastructure** — `docker-compose.yml`, `backend/Dockerfile`, `frontend/Dockerfile`, `backend/railway.json`, `.env.example`
These tell tools (Docker, Railway) how to build and run the whole system together — which containers to start, what ports to use, what environment variables are needed. Change these and you change how the app deploys, not what it does functionally.

**Docs** — `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/agents/**/*.md`
Human-readable explanations of the project: architecture, API reference, and (in `docs/agents/`) records of what each AI-assisted work "slice" was supposed to do and whether it passed testing. Nothing here is executed by a computer — it's for people (and Claude) to read before making changes.

**Tests** — `backend/tests/*.py`, `mobile/integration_test/*.dart`, frontend `*.test.tsx`
Automated checks that run the real code with fake/sample input and confirm the output is correct. Backend tests run via `pytest`; they read the same `models`/`services` code the real app uses, so a broken change here should also break the app.

**Scripts** — `scripts/check_agent_config_sync.py`
Small standalone utilities run manually or in CI (not part of the running app itself) — e.g. checking that two config files stay in sync.

## 4. Cheat sheet

- `.tsx` = React web UI code with TypeScript; open in editor; don't double-click to "run" it.
- `.ts` = TypeScript logic/config; open in editor; not run standalone.
- `.py` = Python backend code or DB migration; run via `uvicorn`/`pytest`/`alembic`, not by double-clicking.
- `.dart` = Flutter mobile app code; run via `flutter run`, needs the Flutter SDK.
- `.md` = Documentation; double-click/open to read, renders nicely, never "runs."
- `.json` = Structured config/data; open to view, edit carefully, not runnable.
- `.yaml`/`.yml` = Config for Docker/CI/tools; indentation-sensitive, not runnable.
- `.css` = Visual styling for the web app; open in editor, only matters paired with `.tsx`.
- `.html` = A single static page; double-click opens it in a browser, but this one expects other compiled files alongside it.
- `.mdc` = Cursor-editor rule files, mirrors of `CLAUDE.md`; docs only.
- `.png`/`.svg` = Images; double-click to view, never run.
- Dockerfile / `.env.example` = Deployment/config templates; never put real secrets in the checked-in copies.
