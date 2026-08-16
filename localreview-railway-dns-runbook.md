# localreview.co.in — Railway + Namecheap runbook

Personal reference from the 2026-08-16 custom-domain pass. Not product docs (`README.md` stays the source of truth for the app).

## Current status (confirm)

| Check | Status | Meaning |
| --- | --- | --- |
| CNAME `www` → `5vtkfdlq.up.railway.app` | **OK** (Railway green; public DNS matches) | Traffic reaches Railway. That is why you see the purple “train has not arrived” page, not Namecheap parking. |
| TXT `_railway-verify.www` | **Not OK** (Railway yellow; Google DNS: name does not exist) | Ownership not proven. No cert, **Not secure**, station 404, AV often blocks the first visit. |
| Internal port **8080** on frontend | **OK** | Railway `$PORT`. Public HTTPS is still **443**. Do not put 8080/3000/8000 in Namecheap. |
| `https://mengplat.up.railway.app` | **OK** to use now | Same frontend service. Use this until `www` is **Active**. |

**Is the yellow TXT an issue?** Yes, **for the custom domain only**. The app on the Railway URL can work. `www.localreview.co.in` will not be a real HTTPS site until that TXT exists and Railway shows **Active**.

---

## Sequence we followed

1. Domain is on **Namecheap**. Hosting is **Railway frontend** (Next.js), not the FastAPI service.
2. Railway **Settings → Public Networking → Custom domain** `www.localreview.co.in`.
3. Railway showed two records. **No port** in DNS.
4. Namecheap **Advanced DNS** — removed parking:
   - Deleted CNAME `www` → `parkingpage.namecheap.com`
   - Deleted URL Redirect `@` → `http://www…` once **ALIAS** `@` was added (two `@` records fight).
5. Namecheap records that belong:

   | Type | Host | Value |
   | --- | --- | --- |
   | CNAME | `www` | `5vtkfdlq.up.railway.app` (must match **this** Railway modal, not an older hostname such as `is360rcb…`) |
   | TXT | `_railway-verify.www` | full `railway-verify=…` from the **www** modal (not Host `_railway-verify` alone — that is apex) |
   | ALIAS | `@` | same Railway hostname **only if** you also add apex `localreview.co.in` in Railway |

6. Public DNS check: `www.localreview.co.in` CNAME = `5vtkfdlq.up.railway.app`. TXT `_railway-verify.www.localreview.co.in` was still **missing**.
7. Browser: `https://www.localreview.co.in` → Railway 404 + Not secure. Expected until TXT verifies.
8. Antivirus block: typical for new domain + missing cert + old parking reputation. Should ease after padlock is green.

**Still to do:** paste TXT host `_railway-verify.www` + full token → Save → wait minutes–hours → Railway **Active** → padlock on `https://www.localreview.co.in`.

---

## Ports (do not mix these up)

| Place | Port | Type it? |
| --- | --- | --- |
| Browser / custom domain | 443 | No |
| Railway Networking (frontend) | **8080** (`$PORT`) | Yes, container target only |
| Local Docker | 3000 frontend, 8000 API | Local only |
| Namecheap | — | Never |

---

## Backend vs frontend env

**Frontend** (same app, two public names after DNS is green):

- `https://www.localreview.co.in`
- `https://mengplat.up.railway.app`

You do **not** QA every change twice. One deploy updates both. Daily URL = custom domain once Active.

Variables (must be the **backend** HTTPS host, not the website):

- `NEXT_PUBLIC_API_URL` = `https://<backend>.up.railway.app` (baked at **build**; redeploy after change)
- `API_URL_INTERNAL` = same (SSR at runtime)
- Yellow **i** in Railway = often “build-time / not in start command”, not “invalid”

**Backend** Variables:

- `CORS_ORIGINS` = **list** of browser origins, e.g.  
  `https://www.localreview.co.in,https://localreview.co.in,https://mengplat.up.railway.app`
- `PUBLIC_APP_URL` = **one** origin for email links, e.g. `https://www.localreview.co.in`

CORS = who may call the API. `PUBLIC_APP_URL` = which link goes in the reset email. Do **not** attach the custom domain to the **backend** service.

---

## Flow (short)

```text
User → https://www.localreview.co.in
     → Namecheap CNAME → Railway edge :443
     → TXT verified → cert + route
     → frontend container :8080
     → browser calls NEXT_PUBLIC_API_URL (backend)
     → backend CORS must allow that page's origin
```

Until TXT is green, the chain stops at Railway edge (station 404).

---

## Why `www` vs apex

- `www.localreview.co.in` — CNAME (what we provisioned).
- `localreview.co.in` (`@`) — optional; needs ALIAS + a second Railway custom domain. Not required if everyone uses `www`.
