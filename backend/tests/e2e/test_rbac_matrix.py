"""RBAC matrix against live API (README §9 / TP-S-010)."""

from __future__ import annotations

from uuid import uuid4

import pytest

from tests.e2e.api_client import Api

pytestmark = pytest.mark.e2e


def test_rbac_matrix(api: Api) -> None:
    anon_review = api.post("reviews", json={"business_id": str(uuid4()), "rating": 5, "body": "x" * 12})
    assert anon_review.status == 401

    dash = api.get(f"dashboard/merchant/{uuid4()}")
    assert dash.status == 401

    cust_email = f"e2e-rbac-c-{uuid4().hex[:10]}@example.com"
    api.register(cust_email, role="customer")
    cust = api.tokens(cust_email)
    create = api.post(
        "businesses",
        token=cust.access_token,
        json={"name": "Nope", "address": "1 A", "city": "X", "country": "IN"},
    )
    assert create.status == 403

    merch_email = f"e2e-rbac-m-{uuid4().hex[:10]}@example.com"
    api.register(merch_email, role="merchant")
    merch = api.tokens(merch_email)
    listings = api.list_businesses()
    biz_id = listings[0].id if listings else api.create_business(merch.access_token, "Rbac Shop").id
    assert api.post(f"businesses/{biz_id}/approve", token=merch.access_token).status == 403
    # S-079: start-review/return-to-pending share approve/suspend's require_roles(ADMIN) gate.
    assert api.post(f"businesses/{biz_id}/start-review", token=merch.access_token).status == 403
    assert api.post(f"businesses/{biz_id}/return-to-pending", token=merch.access_token).status == 403
    if listings:
        fake_review = str(uuid4())
        assert api.post(
            f"reviews/{fake_review}/moderate?action=hide",
            token=merch.access_token,
        ).status in {403, 404, 422}

    assert api.get("dashboard/admin/platform", token=cust.access_token).status == 403
    assert api.get("dashboard/admin/platform", token=merch.access_token).status == 403


def test_ownership_returns_404_or_403(api: Api) -> None:
    listings = api.list_businesses()
    if not listings:
        pytest.skip("Need an existing approved business")
    target = listings[0]
    email = f"e2e-own-{uuid4().hex[:10]}@example.com"
    api.register(email, role="merchant")
    tok = api.tokens(email)
    stolen = api.patch(f"businesses/{target.id}", token=tok.access_token, json={"name": "Hijack"})
    assert stolen.status in {403, 404}
