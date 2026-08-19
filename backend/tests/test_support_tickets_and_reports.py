"""S-087 / S-088 / S-089 — support contact, tickets, shop reports (ASGI + DB)."""

from __future__ import annotations

import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.rate_limit import limiter
from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.main import app
from app.models import User, UserRole
from tests.auth_helpers import complete_password_login, register_and_get_token


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    limiter.reset()
    yield
    limiter.reset()


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
            "name": f"Support Test {uuid.uuid4().hex[:6]}",
            "address": "1 Main St",
            "city": "Chennai",
            "phone": "+919876500003",
            "email": "support-test@example.com",
        },
    )
    assert res.status_code == 201, res.text
    return res.json()


TICKET_BODY = {
    "name": "Guest Person",
    "phone": "+919876543210",
    "issue": "I cannot find my review after submitting it.",
}


@pytest.mark.asyncio
async def test_support_contact_is_public(client):
    response = await client.get("/api/v1/support/contact")
    assert response.status_code == 200
    body = response.json()
    assert "email" in body and body["email"]
    assert body["support_path"] == "/support"


@pytest.mark.asyncio
async def test_guest_can_create_support_ticket(client):
    response = await client.post("/api/v1/support-tickets", json=TICKET_BODY)
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["status"] == "open"
    assert body["reporter_id"] is None
    assert body["business_id"] is None
    assert body["issue"] == TICKET_BODY["issue"]


@pytest.mark.asyncio
async def test_ticket_stores_valid_business_id_and_omits_blank(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])

    with_biz = await client.post(
        "/api/v1/support-tickets",
        json={**TICKET_BODY, "business_id": business["id"]},
    )
    assert with_biz.status_code == 201, with_biz.text
    assert with_biz.json()["business_id"] == business["id"]

    without = await client.post("/api/v1/support-tickets", json=TICKET_BODY)
    assert without.status_code == 201
    assert without.json()["business_id"] is None

    unknown = await client.post(
        "/api/v1/support-tickets",
        json={**TICKET_BODY, "business_id": str(uuid.uuid4())},
    )
    assert unknown.status_code == 400


@pytest.mark.asyncio
async def test_logged_in_user_sees_own_tickets_including_admin_response(client):
    customer = await _register(client, "customer")
    created = await client.post("/api/v1/support-tickets", json=TICKET_BODY, headers=customer["headers"])
    assert created.status_code == 201
    ticket_id = created.json()["id"]

    admin = await _register_admin(client)
    patched = await client.patch(
        f"/api/v1/admin/support-tickets/{ticket_id}",
        headers=admin["headers"],
        json={"status": "in_progress", "admin_response": "We are looking into this."},
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["status"] == "in_progress"
    assert patched.json()["admin_response"] == "We are looking into this."

    mine = await client.get("/api/v1/support-tickets/mine", headers=customer["headers"])
    assert mine.status_code == 200
    match = next(t for t in mine.json() if t["id"] == ticket_id)
    assert match["status"] == "in_progress"
    assert match["admin_response"] == "We are looking into this."


@pytest.mark.asyncio
async def test_admin_can_list_tickets_customer_gets_403(client):
    await client.post("/api/v1/support-tickets", json=TICKET_BODY)
    customer = await _register(client, "customer")
    merchant = await _register(client, "merchant")
    admin = await _register_admin(client)

    listed = await client.get("/api/v1/admin/support-tickets", headers=admin["headers"])
    assert listed.status_code == 200
    assert any(t["issue"] == TICKET_BODY["issue"] for t in listed.json())

    cust = await client.get("/api/v1/admin/support-tickets", headers=customer["headers"])
    assert cust.status_code == 403
    merch = await client.get("/api/v1/admin/support-tickets", headers=merchant["headers"])
    assert merch.status_code == 403
    patch = await client.patch(
        f"/api/v1/admin/support-tickets/{listed.json()[0]['id']}",
        headers=customer["headers"],
        json={"status": "resolved"},
    )
    assert patch.status_code == 403


@pytest.mark.asyncio
async def test_mine_tickets_anonymous_401(client):
    response = await client.get("/api/v1/support-tickets/mine")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_create_shop_report_201_and_anonymous_401(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    customer = await _register(client, "customer")

    created = await client.post(
        f"/api/v1/businesses/{business['id']}/reports",
        headers=customer["headers"],
        json={"reason": "This listing looks like a duplicate shop."},
    )
    assert created.status_code == 201, created.text
    assert created.json()["business_id"] == business["id"]
    assert created.json()["status"] == "open"

    anon = await client.post(
        f"/api/v1/businesses/{business['id']}/reports",
        json={"reason": "This listing looks like a duplicate shop."},
    )
    assert anon.status_code == 401


@pytest.mark.asyncio
async def test_merchant_cannot_report_own_shop(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    response = await client.post(
        f"/api/v1/businesses/{business['id']}/reports",
        headers=merchant["headers"],
        json={"reason": "I want to flag my own listing somehow."},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_queue_flags_repeat_at_three_reports(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    admin = await _register_admin(client)

    for _ in range(3):
        limiter.reset()
        customer = await _register(client, "customer")
        res = await client.post(
            f"/api/v1/businesses/{business['id']}/reports",
            headers=customer["headers"],
            json={"reason": "Spam listing that should be reviewed now."},
        )
        assert res.status_code == 201, res.text

    queued = await client.get("/api/v1/admin/business-reports", headers=admin["headers"])
    assert queued.status_code == 200
    for row in queued.json():
        if row["business_id"] == business["id"]:
            assert row["report_count"] == 3
            assert row["is_repeat"] is True


@pytest.mark.asyncio
async def test_report_message_thread_visible_to_reporter_and_admin(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    customer = await _register(client, "customer")
    admin = await _register_admin(client)

    created = await client.post(
        f"/api/v1/businesses/{business['id']}/reports",
        headers=customer["headers"],
        json={"reason": "Hours on the listing are completely wrong."},
    )
    report_id = created.json()["id"]

    user_msg = await client.post(
        f"/api/v1/business-reports/{report_id}/messages",
        headers=customer["headers"],
        json={"body": "Also the phone number bounces."},
    )
    assert user_msg.status_code == 201, user_msg.text

    admin_msg = await client.post(
        f"/api/v1/admin/business-reports/{report_id}/messages",
        headers=admin["headers"],
        json={"body": "Thanks, we will check with the merchant."},
    )
    assert admin_msg.status_code == 201, admin_msg.text

    mine = await client.get("/api/v1/business-reports/mine", headers=customer["headers"])
    assert mine.status_code == 200
    mine_row = next(r for r in mine.json() if r["id"] == report_id)
    bodies = {m["body"] for m in mine_row["messages"]}
    assert "Also the phone number bounces." in bodies
    assert "Thanks, we will check with the merchant." in bodies

    admin_list = await client.get("/api/v1/admin/business-reports", headers=admin["headers"])
    admin_row = next(r for r in admin_list.json() if r["id"] == report_id)
    admin_bodies = {m["body"] for m in admin_row["messages"]}
    assert bodies <= admin_bodies

    other = await _register(client, "customer")
    forbidden = await client.post(
        f"/api/v1/business-reports/{report_id}/messages",
        headers=other["headers"],
        json={"body": "I should not be able to post here."},
    )
    assert forbidden.status_code == 403

    customer_admin = await client.get("/api/v1/admin/business-reports", headers=customer["headers"])
    assert customer_admin.status_code == 403


@pytest.mark.asyncio
async def test_review_report_endpoint_unchanged(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    admin = await _register_admin(client)
    await client.post(f"/api/v1/businesses/{business['id']}/approve", headers=admin["headers"])

    customer = await _register(client, "customer")
    review = await client.post(
        "/api/v1/reviews",
        headers=customer["headers"],
        json={"business_id": business["id"], "rating": 1, "body": "Not a great experience at all here."},
    )
    assert review.status_code == 201, review.text

    reporter = await _register(client, "customer")
    report = await client.post(
        f"/api/v1/reviews/{review.json()['id']}/report",
        headers=reporter["headers"],
        json={"reason": "This review looks fake and misleading."},
    )
    assert report.status_code == 200, report.text
