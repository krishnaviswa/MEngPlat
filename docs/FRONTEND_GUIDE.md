# MerchantHub AI — Frontend Guide

Beginner-friendly guide to the Next.js frontend.

## Core Concepts

### Props

Props are **inputs passed from a parent component to a child**. They are read-only inside the child.

```tsx
// Parent passes business data down
<BusinessCard business={business} href="/custom-link" />
```

| Component | Key Props |
|-----------|-----------|
| Navbar | `user`, `onLogout` |
| BusinessCard | `business`, `href` |
| ReviewCard | `review`, `onLike`, `onReport`, `showActions` |
| RatingWidget | `value`, `onChange`, `readonly`, `size` |
| AIInsights | `insights` |
| Dashboard | `title`, `description`, `navItems`, `children` |

### State

State is **mutable data managed inside a component**. When state changes, React re-renders the component.

Examples:
- `LoginForm` — `email`, `password`, `error`, `loading`
- `RatingWidget` — `hover` for star preview
- `PhotoGallery` — `selected` for lightbox index
- `MerchantDashboard` — `business`, `stats`, `insights`

### Hooks

| Hook | Purpose | Used In |
|------|---------|---------|
| `useState` | Local component state | LoginForm, RatingWidget, PhotoGallery |
| `useEffect` | Side effects (API calls on mount) | ClientLayout, MerchantDashboard, ProfilePage |
| `useRouter` | Next.js navigation | LoginForm, RegisterForm, SettingsPage |

Custom hooks could be added later (e.g. `useAuth`) to centralize token + user logic.

### Routing (Next.js App Router)

File-based routing under `frontend/src/app/`:

| URL | File | Type |
|-----|------|------|
| `/` | `page.tsx` | Server Component (SSR) |
| `/search` | `search/page.tsx` | Server Component |
| `/businesses/[slug]` | `businesses/[slug]/page.tsx` | Dynamic SSR |
| `/login` | `login/page.tsx` | Client form page |
| `/merchant/dashboard` | `merchant/dashboard/page.tsx` | Client dashboard |

### SSR (Server-Side Rendering)

The server generates HTML **before** sending it to the browser. Used for public pages that benefit from SEO and fast first paint.

**Examples:** Home page, search results, business profiles.

```tsx
// No "use client" — runs on server
export default async function HomePage() {
  const featured = await businesses.list();
  return <div>...</div>;
}
```

### CSR (Client-Side Rendering)

The browser downloads JavaScript and **fetches data after the page loads**. Used for interactive forms and authenticated dashboards.

**Examples:** Login, register, merchant dashboard, admin panel.

```tsx
"use client";
export default function LoginPage() {
  const [email, setEmail] = useState("");
  // ...
}
```

### Hybrid Pattern

Next.js App Router uses **Server Components by default**. Add `"use client"` at the top of files that need browser APIs, event handlers, or hooks.

---

## Component Reference

See `frontend/src/components/` for implementations. Each file includes a JSDoc comment explaining purpose, props, and state.

| Component | File | Description |
|-----------|------|-------------|
| Navbar | `Navbar.tsx` | Global nav, role-aware links |
| Footer | `Footer.tsx` | Site footer |
| BusinessCard | `BusinessCard.tsx` | Search result card |
| ReviewCard | `ReviewCard.tsx` | Review with AI badge |
| RatingWidget | `RatingWidget.tsx` | Star rating input/display |
| SearchBar | `SearchBar.tsx` | Search form |
| FilterPanel | `FilterPanel.tsx` | Search filters |
| Dashboard | `Dashboard.tsx` | Dashboard layout shell |
| Charts | `Charts.tsx` | Recharts sentiment chart |
| PhotoGallery | `PhotoGallery.tsx` | Image grid + lightbox |
| LoginForm | `LoginForm.tsx` | Login form |
| RegisterForm | `RegisterForm.tsx` | Registration form |
| ProfilePage | `ProfilePage.tsx` | User profile |
| SettingsPage | `SettingsPage.tsx` | Settings + logout |
| AIInsights | `AIInsights.tsx` | Merchant AI panel |
| MerchantDashboard | `MerchantDashboard.tsx` | Full merchant dashboard |
