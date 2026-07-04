# API Reference

Base URL: `http://localhost:8000/api/v1`

Interactive docs: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## Authentication (`/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | Public | Create account |
| POST | `/auth/login` | Public | Get JWT tokens |
| POST | `/auth/refresh` | Public | Refresh tokens |
| GET | `/auth/me` | Bearer | Current user |
| POST | `/auth/oauth/callback` | Public | OAuth placeholder |
| POST | `/auth/logout` | Public | Logout placeholder |

### POST `/auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "full_name": "Jane Doe",
  "password": "securepass123",
  "role": "customer"
}
```

**Response:** `201` User object

### POST `/auth/login`

**Request:**
```json
{ "email": "user@example.com", "password": "securepass123" }
```

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

---

## Businesses (`/businesses`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/businesses` | Public | List businesses |
| GET | `/businesses/categories/all` | Public | List categories |
| GET | `/businesses/{slug}` | Public | Get by slug |
| POST | `/businesses` | Merchant | Create business |
| PATCH | `/businesses/{id}` | Merchant/Admin | Update business |
| POST | `/businesses/{id}/approve` | Admin | Approve listing |
| POST | `/businesses/{id}/suspend` | Admin | Suspend listing |
| POST | `/businesses/categories` | Admin | Create category |

---

## Reviews (`/reviews`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/reviews/business/{business_id}` | Public | List reviews |
| POST | `/reviews` | User | Create review (+ AI) |
| PATCH | `/reviews/{id}` | Author | Edit review |
| DELETE | `/reviews/{id}` | Author | Delete review |
| POST | `/reviews/{id}/like` | User | Like review |
| POST | `/reviews/{id}/report` | User | Report review |
| POST | `/reviews/{id}/reply` | Merchant | Reply to review |
| POST | `/reviews/{id}/moderate` | Admin | Hide/restore/remove |

### POST `/reviews`

**Request:**
```json
{
  "business_id": "uuid",
  "rating": 5,
  "title": "Great coffee!",
  "body": "Friendly staff and excellent pastries. Will return!"
}
```

**Response:** Review with `ai_analysis` containing sentiment, summary, suggested_response

---

## Photos (`/photos`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/photos/upload` | User | Upload photo (multipart) |
| GET | `/photos/business/{id}` | Public | Business gallery |
| DELETE | `/photos/{id}` | Merchant/Admin | Delete photo |

**Upload form fields:** `file`, `business_id`, `review_id`, `photo_type`, `caption`

---

## AI Analysis (`/ai`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/ai/reviews/{review_id}` | Public | Review AI analysis |
| GET | `/ai/businesses/{id}/insights` | Merchant | Merchant AI insights |
| POST | `/ai/businesses/{id}/refresh` | Merchant | Refresh AI summary |

---

## Dashboard (`/dashboard`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/dashboard/merchant/{business_id}` | Merchant | Merchant dashboard stats |
| GET | `/dashboard/admin/platform` | Admin | Platform analytics |

---

## Search (`/search`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/search/businesses` | Public | Search + filter |

**Query params:** `q`, `city`, `category`, `min_rating`, `sentiment`, `lat`, `lng`, `radius_km`, `page`, `page_size`

---

## Maps (`/maps`) — Placeholder

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/maps/nearby` | Public | Nearby businesses placeholder |
| GET | `/maps/geocode` | Public | Geocode placeholder |
| GET | `/maps/config` | Public | Maps config for frontend |

---

## Analytics (`/analytics`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/analytics/merchant/{id}` | Merchant | AI insights alias |
| GET | `/analytics/merchant/{id}/summary` | Merchant | Quick KPI summary |

---

## Notifications (`/notifications`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/notifications` | Bearer | List notifications |
| POST | `/notifications/{id}/read` | Bearer | Mark one read |
| POST | `/notifications/read-all` | Bearer | Mark all read |

---

## Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service health check |
