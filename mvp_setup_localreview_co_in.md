# MVP Setup Checklist for localreview.co.in

This document outlines the step-by-step action plan to set up your MVP with:
- Domain: `localreview.co.in` (Namecheap)
- Business Email: `contact@localreview.co.in` (Namecheap Private Email)
- Hosting + SSL: Railway (automatic HTTPS)
- Email Authentication: SPF, DKIM, DMARC configured in Namecheap DNS

---

## 1. Buy and Secure the Domain

**Actions:**

- [ ] Go to [Namecheap](https://www.namecheap.com/)
- [ ] Search and purchase:
  - [ ] `localreview.co.in` (primary domain)
  - [ ] (Optional) `localreview.in` (to redirect to `localreview.co.in` later)
- [ ] Ensure domain is registered under your Namecheap account

**Why:**
- Lock your core brand now while you test traction.
- You can add more TLDs later if needed.

---

## 2. Set Up Business Email on Namecheap

**Actions:**

- [ ] In your Namecheap account:
  - [ ] Add **Private Email** plan (start with 1 mailbox)
- [ ] Create mailbox:
  - [ ] Username: `contact`
  - [ ] Domain: `localreview.co.in`
  - [ ] Result: `contact@localreview.co.in`
- [ ] Note the mail server settings shown (MX, SPF, DKIM, DMARC values)

**Cost Expectation:**
- Approximately **$10–$15/year** for 1 basic mailbox. [18][25]

**Use This Email:**

- [ ] Put `contact@localreview.co.in` in:
  - [ ] Site footer ("Contact: contact@localreview.co.in")
  - [ ] "Contact" / "About" page
  - [ ] Any outreach to users/partners

This immediately improves perceived authenticity vs a generic Gmail. [21][24]

---

## 3. Configure DNS for Email (SPF, DKIM, DMARC)

In Namecheap, go to:  
**Domain List → localreview.co.in → Manage → Advanced DNS**

> Use the exact values Namecheap provides for Private Email. The examples below show typical patterns.

### 3.1 MX Records (for Receiving Email)

- [ ] Add MX records as provided by Namecheap, e.g.:

```dns
Type: MX
Host: @
Value: mx1.privateemail.com
Priority: 10

Type: MX
Host: @
Value: mx2.privateemail.com
Priority: 20
```

### 3.2 SPF Record

- [ ] Add a TXT record for SPF, e.g.:

```dns
Type: TXT
Host: @
Value: v=spf1 include:spf.privateemail.com ~all
```

(Use the exact value Namecheap gives you.)

This tells other servers which hosts are allowed to send email from `localreview.co.in`. [16][19]

### 3.3 DKIM Record

- [ ] Add DKIM record as provided by Namecheap, e.g.:

```dns
Type: TXT
Host: default._domainkey
Value: v=DKIM1; k=rsa; p=MIIBIjANBgkq...long-key...
```

Add exactly what they provide. This lets receivers verify that emails from your domain are genuinely from you. [16][19]

### 3.4 DMARC Record

- [ ] Add a DMARC policy to start in "monitor" mode:

```dns
Type: TXT
Host: _dmarc
Value: v=DMARC1; p=none; rua=mailto:dmarc-reports@localreview.co.in
```

- `p=none` = just monitor, don't reject yet.
- `rua=mailto:...` = optional reports address (can be same as `contact@...` or a separate one). [16][26]

Once email is working smoothly for a few weeks, you can tighten DMARC to `p=quarantine` or `p=reject`.

---

## 4. Connect Your Domain to Railway (Hosting + SSL)

**You do NOT need to buy SSL separately.** Railway handles HTTPS automatically. [32]

**Actions:**

- [ ] In Railway:
  - [ ] Go to your project → **Settings** → **Domains**
  - [ ] Add custom domain: `localreview.co.in`
  - [ ] (Optional) Add `www.localreview.co.in`
- [ ] Railway will show DNS records to add (A and/or CNAME)
- [ ] In Namecheap DNS for `localreview.co.in`:
  - [ ] Add the records Railway gives you, e.g.:

```dns
Type: A
Host: @
Value: <Railway IP>

Type: CNAME
Host: www
Value: <Railway-provided-domain>
```

- [ ] Wait for DNS propagation (usually minutes to a couple of hours)
- [ ] Railway will automatically issue and renew an SSL certificate for:
  - [ ] `localreview.co.in`
  - [ ] `www.localreview.co.in`

No need to buy "SSL standard termination" from Namecheap.

---

## 5. Multi-Domain / Multi-UI Strategy (Keep It Simple for MVP)

For your MVP targeting India + global:

**Recommended Approach:**

- [ ] Use **one domain**: `localreview.co.in`
- [ ] Implement region logic in the app:
  - [ ] Detect user location or let them choose
  - [ ] Show India-specific reviews under `/in` or via a toggle
  - [ ] Show global content as default or under `/global`

**Example URLs:**

- `https://localreview.co.in` – default (global or auto-detected)
- `https://localreview.co.in/in` – India-focused view
- `https://localreview.co.in/global` – global view

**Avoid:**
- Creating multiple TLDs (.shop, .tech, etc.) until you have real traction. It splits SEO and complicates things. [4][10][12]

**Later (if needed):**
- [ ] Buy another domain (e.g., `localreview.shop`) and point it to a different UI on the same backend.

But for now: **one domain, one brand, multiple views** is enough.

---

## 6. Test Everything

### 6.1 Email Tests

- [ ] Send test emails:
  - [ ] From `contact@localreview.co.in` to Gmail, Outlook, etc.
  - [ ] Check that they land in inbox, not spam
- [ ] Use tools to verify SPF/DKIM/DMARC:
  - [ ] https://mxtoolbox.com/
  - [ ] Google's "Check MX" / "Test email authentication"
- [ ] Confirm no authentication warnings in receiving mail clients. [16][19][26]

### 6.2 Website Tests

- [ ] Visit:
  - [ ] `https://localreview.co.in`
  - [ ] `https://www.localreview.co.in`
- [ ] Confirm:
  - [ ] HTTPS works (padlock in browser)
  - [ ] No SSL warnings
- [ ] Check that your backend correctly handles the `Host` header if you later add more domains.

---

## 7. Run Your MVP for 3–6 Months

With this setup:

- **Domain:** `localreview.co.in` (Namecheap)
- **Email:** `contact@localreview.co.in` (Namecheap Private Email)
- **Hosting + SSL:** Railway (automatic HTTPS)
- **SPF/DKIM/DMARC:** Configured for trust and deliverability

**Focus on:**

- [ ] Getting real users (India + global)
- [ ] Iterating features and UI
- [ ] Measuring traction (signups, repeat visits, engagement)

**Only consider:**

- Adding more domains, or
- Moving to a different hosting stack

once you have clear signals that it's worth the extra complexity and cost.

---

## Quick Reference: What Each Piece Does

- **Domain (`localreview.co.in`)**: Your brand address on the internet.
- **Business Email (`contact@localreview.co.in`)**: Professional contact address that improves trust and deliverability. [21][24]
- **MX Records**: Direct incoming email to Namecheap's mail servers.
- **SPF**: Lists servers allowed to send email from your domain. [16][19]
- **DKIM**: Adds a cryptographic signature to prove email authenticity. [16][19]
- **DMARC**: Defines policy for handling emails that fail SPF/DKIM and provides reports. [16][26]
- **Railway Hosting**: Runs your backend/frontend app with automatic HTTPS. [32]
- **SSL (via Railway)**: Encrypts traffic between users and your site; no separate purchase needed. [32]

---

## Notes

- Replace example DNS values with the exact ones provided by Namecheap and Railway.
- Keep this checklist handy and tick off items as you complete them.
- Once stable, you can tighten DMARC policy and consider additional mailboxes (e.g., `support@localreview.co.in`).

---

**Sources:**

- [16] Microsoft: How email authentication works (SPF, DKIM, DMARC)
- [18] Namecheap: Private Email pricing and plans
- [19] Twilio: How to authenticate email (SPF, DKIM, DMARC)
- [21] Spaceship: Why domain name and email should match
- [24] Networksolutions: Benefits of professional email for business
- [25] Mailreach: Namecheap Private Email overview
- [26] LinkedIn: Gmail trust issues and DMARC
- [32] Railway: Automatic SSL for custom domains
- [4] Shopify: Multi-domain SEO considerations
- [10] Carrot: Domain name best practices
- [12] Reddit: How long Google takes to trust new domains
