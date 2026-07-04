# Entity Relationship Diagram

## ERD

```mermaid
erDiagram
    users ||--o| merchants : "has optional"
    merchants ||--o{ businesses : owns
    businesses }o--o{ categories : "via business_categories"
    users ||--o{ reviews : writes
    businesses ||--o{ reviews : receives
    reviews ||--o{ photos : attaches
    reviews ||--o| ai_analyses : "text analysis"
    photos ||--o| ai_analyses : "image analysis"
    reviews ||--o| replies : "merchant reply"
    users ||--o{ review_likes : likes
    users ||--o{ review_reports : reports
    users ||--o{ favorites : saves
    users ||--o{ notifications : receives
    users ||--o{ audit_logs : "admin actions"

    users {
        uuid id PK
        string email UK
        string hashed_password
        string full_name
        enum role
        bool is_active
    }

    merchants {
        uuid id PK
        uuid user_id FK UK
        string phone
    }

    businesses {
        uuid id PK
        uuid merchant_id FK
        string name
        string slug UK
        string address
        string city
        float latitude
        float longitude
        enum status
        float average_rating
        int review_count
        jsonb ai_positives
        jsonb ai_complaints
    }

    categories {
        uuid id PK
        string name UK
        string slug UK
    }

    reviews {
        uuid id PK
        uuid business_id FK
        uuid author_id FK
        int rating
        text body
        enum status
        int like_count
    }

    ai_analyses {
        uuid id PK
        uuid review_id FK
        uuid photo_id FK
        enum sentiment
        text summary
        jsonb image_insights
        text suggested_response
    }

    photos {
        uuid id PK
        uuid business_id FK
        uuid review_id FK
        string url
        string photo_type
    }
```

## Relationship Explanations

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| User → Merchant | 1:0..1 | A user with role `merchant` has one merchant profile |
| Merchant → Business | 1:N | A merchant can own multiple business listings |
| Business ↔ Category | M:N | Via `business_categories` junction table |
| User → Review | 1:N | Customers write many reviews |
| Business → Review | 1:N | Each review belongs to one business |
| Review → Photo | 1:N | Reviews can include photo attachments |
| Review → AIAnalysis | 1:1 | Each review gets one text AI analysis |
| Photo → AIAnalysis | 1:1 | Each photo can get image AI analysis |
| Review → Reply | 1:1 | Merchant can post one public reply per review |
| User → ReviewLike | M:N | Via `review_likes` — customers like reviews |
| User → Favorite | M:N | Customers save favorite businesses |
| User → Notification | 1:N | System sends notifications to users |
| User → AuditLog | 1:N | Admin actions are logged |

## Indexes & Constraints

- Unique: `users.email`, `businesses.slug`, `categories.slug`
- Unique pairs: `(user_id, business_id)` on favorites, `(user_id, review_id)` on likes
- Foreign keys with CASCADE on delete for reviews, photos, etc.
