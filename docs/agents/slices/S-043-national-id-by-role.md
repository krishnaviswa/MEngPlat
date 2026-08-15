# Slice: S-043 — National ID by role

| Field | Value |
|-------|-------|
| **Slice ID** | S-043 |
| **Phase** | 1 Foundation |
| **Status** | Accepted |
| **Role(s)** | merchant, customer, admin |
| **Owner** | PM / 2026-08-15 |

---

## User story

Merchants must supply PAN, Aadhaar, or other national ID before creating a listing. Customers optional. Admins optional. Admin user list shows a masked number. Not government KYC.

---

## Acceptance criteria

1. Types include pan, aadhaar, other.
2. Merchant `POST /businesses` is 400 without ID.
3. Customer/admin may omit ID.
4. Admin user list masks the number.
5. Merchant dashboard has a national ID fieldset (including empty state). Copy says not verified KYC.

---

## Technical specification (Architect)

Validate in `create_business`. Mask in `admin_users` list/suspend/reactivate. Alembic adds `aadhaar` enum value.

---

## Links

- Test report: `docs/agents/test-reports/TR-S-043-national-id-by-role.md`
