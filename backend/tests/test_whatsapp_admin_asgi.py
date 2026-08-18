"""S-053 admin approval gate for WhatsApp-derived profile drafts -- RBAC and
happy-path coverage via the real FastAPI DI chain + real Postgres.

test_whatsapp.py already covers `admin_approve_draft` / `admin_reject_draft`
service-layer logic (edited-field override, double-approve 409, notify) via
its single-business-scoped `InMemoryDB` fake -- same limitation noted in that
file: a direct function call never resolves `Depends(require_roles(...))`,
and the fake can't represent `list_pending_drafts_admin`'s true cross-business
join. This file closes both gaps end-to-end: 401/403 on every new
`/admin/whatsapp/drafts*` route, the removed merchant apply/discard routes
(404), merchant ownership on the (widened) `GET .../whatsapp/drafts`
endpoint, and the admin queue's real cross-business join/pagination/FIFO
ordering that the fake DB structurally cannot exercise.

Uses ASGI + a real database, same pattern as test_dashboard.py and
test_admin_platform_asgi.py. NOTE: never run this file locally against the
project's dev DATABASE_URL -- see backend/tests/CLAUDE.md; it's meant for
CI's ephemeral Postgres service container only. Same known
function-scoped-event-loop flake documented in test_whatsapp.py's and
test_admin_platform_asgi.py's module docstrings applies here when this file
is run alongside other DB-touching test modules in one pytest process; each
test was verified in this session -- see the test report for the exact
command(s) and real pass/fail tally.

The admin queue is a global, unbounded (shared-DB) list -- tests never assert
it is *exactly* N items or *exactly* empty; they instead scope assertions to
rows this file itself creates (matched by id) so they're robust to leftover
data from other test runs against the same database.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.main import app
from app.models import AuditLog, Business, BusinessUpdateDraft, DraftStatus, Notification, User, UserRole
from tests.auth_helpers import complete_password_login, register_and_get_token


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register(client: AsyncClient, role: str, email: str | None = None) -> dict:
    email = email or f"{role}-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role=role, full_name=f"Test {role.title()}")
    return {"email": email, "headers": {"Authorization": f"Bearer {token}"}}


async def _register_admin(client: AsyncClient) -> dict:
    """POST /auth/register blocks self-registering as admin (by design), so
    seed the row directly via a real session and log in normally -- there's
    no API path to mint an admin account."""
    email = f"admin-{uuid.uuid4().hex[:8]}@example.com"
    password = "testpass1234"
    async with AsyncSessionLocal() as db:
        db.add(
            User(
                email=email,
                full_name="Test Admin",
                hashed_password=get_password_hash(password),
                role=UserRole.ADMIN,
                is_active=True,
            )
        )
        await db.commit()

    tokens = await complete_password_login(client, email, password)
    return {"email": email, "headers": {"Authorization": f"Bearer {tokens['access_token']}"}}


async def _create_business(client: AsyncClient, merchant_headers: dict) -> dict:
    res = await client.post(
        "/api/v1/businesses",
        headers=merchant_headers,
        json={
            "name": f"WA Admin Test {uuid.uuid4().hex[:6]}",
            "address": "1 Main St",
            "city": "Chennai",
            "phone": "+919876500005",
            "email": "wa-admin-test@example.com",
        },
    )
    assert res.status_code == 201, res.text
    return res.json()


async def _seed_draft(
    business_id: str,
    extracted_fields: dict,
    *,
    degraded: bool = False,
    created_at: datetime | None = None,
) -> str:
    async with AsyncSessionLocal() as db:
        draft = BusinessUpdateDraft(
            business_id=uuid.UUID(business_id),
            source="whatsapp",
            extracted_fields=extracted_fields,
            status=DraftStatus.PENDING,
            degraded=degraded,
        )
        if created_at is not None:
            draft.created_at = created_at
        db.add(draft)
        await db.commit()
        await db.refresh(draft)
        return str(draft.id)


# ---------------------------------------------------------------------------
# RBAC: 401 anonymous / 403 wrong role on every new/changed S-053 route.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_admin_queue_anonymous_401(client):
    response = await client.get("/api/v1/admin/whatsapp/drafts")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_admin_queue_requires_admin_role_customer_403(client):
    customer = await _register(client, "customer")
    response = await client.get("/api/v1/admin/whatsapp/drafts", headers=customer["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_queue_requires_admin_role_merchant_403(client):
    merchant = await _register(client, "merchant")
    response = await client.get("/api/v1/admin/whatsapp/drafts", headers=merchant["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_approve_draft_anonymous_401(client):
    response = await client.post(f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/approve")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_approve_draft_requires_admin_role_customer_403(client):
    customer = await _register(client, "customer")
    response = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/approve", headers=customer["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_approve_draft_refused_for_owning_merchant_403(client):
    """AC6/AC7: even the merchant who owns the business the draft belongs to
    can no longer approve it -- only admin."""
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    draft_id = await _seed_draft(business["id"], {"description": "AI desc"})

    response = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{draft_id}/approve", headers=merchant["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_reject_draft_anonymous_401(client):
    response = await client.post(f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/reject")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_reject_draft_requires_admin_role_customer_403(client):
    customer = await _register(client, "customer")
    response = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/reject", headers=customer["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_old_merchant_apply_route_no_longer_exists_404(client):
    """AC6/AC7: the removed route 404s for anyone, including admin -- there
    is no route at any auth level, not merely an RBAC lock."""
    admin = await _register_admin(client)
    response = await client.post(
        f"/api/v1/dashboard/merchant/{uuid.uuid4()}/whatsapp/drafts/{uuid.uuid4()}/apply",
        headers=admin["headers"],
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_old_merchant_discard_route_no_longer_exists_404(client):
    admin = await _register_admin(client)
    response = await client.post(
        f"/api/v1/dashboard/merchant/{uuid.uuid4()}/whatsapp/drafts/{uuid.uuid4()}/discard",
        headers=admin["headers"],
    )
    assert response.status_code == 404


# ---------------------------------------------------------------------------
# Merchant read-only list endpoint: ownership + all-statuses (AC5).
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_merchant_cannot_list_another_merchants_drafts_403(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    other_merchant = await _register(client, "merchant")

    response = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}/whatsapp/drafts", headers=other_merchant["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_merchant_list_endpoint_shows_all_statuses_newest_first(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])

    older_id = await _seed_draft(
        business["id"], {"description": "old suggestion"}, created_at=datetime.now(UTC) - timedelta(hours=1)
    )
    newer_id = await _seed_draft(business["id"], {"description": "new suggestion"})

    # Resolve the older one so the merchant sees a non-pending status too.
    reject = await client.post(f"/api/v1/admin/whatsapp/drafts/{older_id}/reject", headers=admin["headers"])
    assert reject.status_code == 200, reject.text

    listing = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}/whatsapp/drafts", headers=merchant["headers"]
    )
    assert listing.status_code == 200, listing.text
    rows = listing.json()
    by_id = {row["id"]: row for row in rows}
    assert by_id[older_id]["status"] == "discarded"
    assert by_id[newer_id]["status"] == "pending"
    # newest first
    ids_in_order = [row["id"] for row in rows if row["id"] in (older_id, newer_id)]
    assert ids_in_order.index(newer_id) < ids_in_order.index(older_id)


# ---------------------------------------------------------------------------
# Approve / reject happy paths (AC2, AC3, AC4) + 404/409.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    ai_fields = {"description": "AI-written description", "address": "AI-written address"}
    draft_id = await _seed_draft(business["id"], ai_fields)

    approve = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{draft_id}/approve",
        headers=admin["headers"],
        json={"fields": {"description": "Admin-corrected description"}},
    )
    assert approve.status_code == 200, approve.text
    assert approve.json()["status"] == "applied"

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Business).where(Business.id == uuid.UUID(business["id"])))
        live_business = result.scalar_one()
        assert live_business.description == "Admin-corrected description"
        assert live_business.address == "AI-written address"

        audit_result = await db.execute(
            select(AuditLog).where(
                AuditLog.entity_type == "business_update_draft",
                AuditLog.entity_id == draft_id,
            )
        )
        audit = audit_result.scalar_one()
        assert audit.action == "approve"
        assert audit.details["ai_fields"]["description"] == "AI-written description"
        assert audit.details["applied_fields"]["description"] == "Admin-corrected description"
        assert audit.details["applied_fields"]["address"] == "AI-written address"

        merchant_user_id = (
            await db.execute(select(User).where(User.email == merchant["email"]))
        ).scalar_one().id
        notif_result = await db.execute(
            select(Notification).where(
                Notification.user_id == merchant_user_id, Notification.title == "WhatsApp update applied"
            )
        )
        assert notif_result.scalar_one_or_none() is not None


@pytest.mark.asyncio
async def test_admin_reject_leaves_business_unchanged_and_notifies(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    draft_id = await _seed_draft(business["id"], {"description": "should not be applied"})

    reject = await client.post(f"/api/v1/admin/whatsapp/drafts/{draft_id}/reject", headers=admin["headers"])
    assert reject.status_code == 200, reject.text
    assert reject.json()["status"] == "discarded"

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Business).where(Business.id == uuid.UUID(business["id"])))
        live_business = result.scalar_one()
        assert live_business.description is None

        audit_result = await db.execute(
            select(AuditLog).where(
                AuditLog.entity_type == "business_update_draft",
                AuditLog.entity_id == draft_id,
            )
        )
        audit = audit_result.scalar_one()
        assert audit.action == "reject"

        merchant_user_id = (
            await db.execute(select(User).where(User.email == merchant["email"]))
        ).scalar_one().id
        notif_result = await db.execute(
            select(Notification).where(
                Notification.user_id == merchant_user_id,
                Notification.title == "WhatsApp suggestion not applied",
            )
        )
        assert notif_result.scalar_one_or_none() is not None


@pytest.mark.asyncio
async def test_admin_approve_unknown_draft_404(client):
    admin = await _register_admin(client)
    response = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/approve", headers=admin["headers"]
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_admin_reject_unknown_draft_404(client):
    admin = await _register_admin(client)
    response = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{uuid.uuid4()}/reject", headers=admin["headers"]
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_double_approve_is_409_no_double_write(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    draft_id = await _seed_draft(business["id"], {"description": "once only"})

    first = await client.post(f"/api/v1/admin/whatsapp/drafts/{draft_id}/approve", headers=admin["headers"])
    assert first.status_code == 200, first.text

    second = await client.post(f"/api/v1/admin/whatsapp/drafts/{draft_id}/approve", headers=admin["headers"])
    assert second.status_code == 409

    third = await client.post(f"/api/v1/admin/whatsapp/drafts/{draft_id}/reject", headers=admin["headers"])
    assert third.status_code == 409


# ---------------------------------------------------------------------------
# Admin queue: real cross-business join, FIFO ordering, pagination, business
# name + degraded flag surfaced (AC1, AC9, AC11) -- the fake-DB coverage gap.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_admin_queue_lists_across_businesses_oldest_first_with_business_context(client):
    admin = await _register_admin(client)
    merchant_a = await _register(client, "merchant")
    merchant_b = await _register(client, "merchant")
    business_a = await _create_business(client, merchant_a["headers"])
    business_b = await _create_business(client, merchant_b["headers"])

    now = datetime.now(UTC)
    oldest_id = await _seed_draft(
        business_a["id"], {"description": "oldest"}, created_at=now - timedelta(minutes=30)
    )
    middle_id = await _seed_draft(
        business_b["id"], {"description": "middle"}, degraded=True, created_at=now - timedelta(minutes=20)
    )
    newest_id = await _seed_draft(business_a["id"], {"description": "newest"}, created_at=now - timedelta(minutes=10))

    response = await client.get(
        "/api/v1/admin/whatsapp/drafts?page=1&page_size=100", headers=admin["headers"]
    )
    assert response.status_code == 200, response.text
    body = response.json()
    ours = [row for row in body["items"] if row["id"] in (oldest_id, middle_id, newest_id)]
    assert len(ours) == 3
    # FIFO -- oldest created_at first, regardless of business.
    assert [row["id"] for row in ours] == [oldest_id, middle_id, newest_id]

    by_id = {row["id"]: row for row in ours}
    assert by_id[oldest_id]["business_id"] == business_a["id"]
    assert by_id[oldest_id]["business_name"] == business_a["name"]
    assert by_id[middle_id]["business_id"] == business_b["id"]
    assert by_id[middle_id]["business_name"] == business_b["name"]
    assert by_id[middle_id]["degraded"] is True
    assert by_id[newest_id]["degraded"] is False
    assert body["total"] >= 3
    assert body["page"] == 1
    assert body["page_size"] == 100


@pytest.mark.asyncio
async def test_admin_queue_pagination_bounds_page_size(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    now = datetime.now(UTC)
    ids = [
        await _seed_draft(business["id"], {"description": f"page test {i}"}, created_at=now - timedelta(minutes=i))
        for i in range(3)
    ]

    page1 = await client.get(
        "/api/v1/admin/whatsapp/drafts?page=1&page_size=1", headers=admin["headers"]
    )
    assert page1.status_code == 200, page1.text
    body1 = page1.json()
    assert len(body1["items"]) == 1
    assert body1["page"] == 1
    assert body1["page_size"] == 1
    assert body1["total"] >= 3

    # Approve every draft we made so we don't leave permanent pending noise
    # in the shared database for subsequent runs.
    for draft_id in ids:
        res = await client.post(
            f"/api/v1/admin/whatsapp/drafts/{draft_id}/reject", headers=admin["headers"]
        )
        assert res.status_code in (200, 409)


@pytest.mark.asyncio
async def test_admin_queue_pending_only_excludes_resolved_drafts(client):
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    draft_id = await _seed_draft(business["id"], {"description": "will be approved"})

    approve = await client.post(
        f"/api/v1/admin/whatsapp/drafts/{draft_id}/approve", headers=admin["headers"]
    )
    assert approve.status_code == 200, approve.text

    response = await client.get(
        "/api/v1/admin/whatsapp/drafts?page=1&page_size=100", headers=admin["headers"]
    )
    assert response.status_code == 200, response.text
    ids = [row["id"] for row in response.json()["items"]]
    assert draft_id not in ids
