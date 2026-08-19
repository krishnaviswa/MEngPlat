"""Profile avatar upload (S-085) -- POST /api/v1/auth/me/avatar."""

import ast
import inspect
import uuid
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.rate_limit import limiter
from app.main import app
from tests.auth_helpers import register_and_get_token


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    """register/login are rate-limited and the limiter is a shared
    module-level singleton keyed by client IP -- every request in this file
    resolves to the same test-client IP, so without a reset each test would
    silently borrow from a previous test's quota (same convention as
    test_forgot_reset_password.py / test_rate_limit.py)."""
    limiter.reset()
    yield
    limiter.reset()


PNG_BYTES = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
    b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
)


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register(client: AsyncClient, role: str = "customer") -> dict:
    email = f"{role}-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role=role, full_name="Avatar User")
    return {"headers": {"Authorization": f"Bearer {token}"}}


def _avatar_files(name: str = "avatar.png", content_type: str = "image/png", data: bytes = PNG_BYTES):
    return {"file": (name, data, content_type)}


async def _promote_to_admin(user_id: str) -> None:
    """Public /auth/register forbids self-registering as admin, so to cover
    the admin case for AC8's "all roles identical" RBAC matrix, register as a
    customer then flip the role directly at the DB layer."""
    from sqlalchemy import select

    from app.database import AsyncSessionLocal
    from app.models import User, UserRole

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one()
        user.role = UserRole.ADMIN
        await db.commit()


@pytest.mark.asyncio
@pytest.mark.parametrize("role", ["customer", "merchant", "admin"])
async def test_avatar_upload_succeeds_and_updates_avatar_url(client, role):
    reg_role = "customer" if role == "admin" else role
    account = await _register(client, reg_role)

    if role == "admin":
        me = await client.get("/api/v1/auth/me", headers=account["headers"])
        await _promote_to_admin(me.json()["id"])

    res = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(),
    )
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["avatar_url"]
    assert body["avatar_url"].startswith("/uploads/avatars/") or body["avatar_url"].startswith("http")

    me = await client.get("/api/v1/auth/me", headers=account["headers"])
    assert me.status_code == 200
    assert me.json()["avatar_url"] == body["avatar_url"]


@pytest.mark.asyncio
async def test_avatar_upload_oversized_file_rejected_and_previous_unchanged(client):
    account = await _register(client)

    first = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(),
    )
    assert first.status_code == 200, first.text
    original_url = first.json()["avatar_url"]

    too_big = b"\x00" * (5 * 1024 * 1024 + 1)
    res = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(data=too_big),
    )
    assert res.status_code == 400, res.text
    assert "too large" in res.json()["detail"].lower()

    me = await client.get("/api/v1/auth/me", headers=account["headers"])
    assert me.json()["avatar_url"] == original_url


@pytest.mark.asyncio
async def test_avatar_upload_disallowed_content_type_rejected(client):
    account = await _register(client)

    res = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(name="avatar.txt", content_type="text/plain", data=b"not an image"),
    )
    assert res.status_code == 400, res.text
    assert "unsupported file type" in res.json()["detail"].lower()


@pytest.mark.asyncio
async def test_avatar_upload_unauthenticated_rejected(client):
    res = await client.post("/api/v1/auth/me/avatar", files=_avatar_files())
    assert res.status_code == 401, res.text


@pytest.mark.asyncio
async def test_avatar_upload_deletes_old_avatar_file_on_replace(client):
    account = await _register(client)

    first = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(),
    )
    assert first.status_code == 200, first.text
    old_url = first.json()["avatar_url"]

    with patch("app.services.avatar_service.get_storage_provider") as mock_get_provider:
        mock_provider = AsyncMock()
        mock_provider.save.return_value = "/uploads/avatars/new-file.png"
        mock_get_provider.return_value = mock_provider

        second = await client.post(
            "/api/v1/auth/me/avatar",
            headers=account["headers"],
            files=_avatar_files(),
        )
        assert second.status_code == 200, second.text
        mock_provider.delete.assert_awaited_once_with(old_url)


@pytest.mark.asyncio
async def test_avatar_upload_replace_does_not_error_when_old_avatar_is_external_url(client):
    """Old avatar_url set to an external (non-storage-owned) URL, e.g. a Google
    profile picture, must not cause the replace to fail -- both storage
    providers no-op safely on a URL/key they don't recognize."""
    account = await _register(client)

    external_url = "https://lh3.googleusercontent.com/a/some-google-avatar.jpg"

    # UserProfileUpdate still technically allows avatar_url via PATCH
    # /auth/me (schema unchanged per the Architect spec), but the frontend no
    # longer submits it there after this slice -- so simulate the realistic
    # "old avatar_url is external" case (Google picture / legacy pasted URL)
    # by setting it directly at the DB layer, then exercise the real service
    # function (real LocalStorageProvider, not mocked) to confirm the
    # best-effort delete of a URL it doesn't own never raises.
    from app.database import AsyncSessionLocal
    from app.models import User
    from sqlalchemy import select

    me = await client.get("/api/v1/auth/me", headers=account["headers"])
    user_id = me.json()["id"]

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one()
        user.avatar_url = external_url
        await db.commit()

    # Real HTTP path + real LocalStorageProvider.delete() -- an external
    # https:// URL must be a silent no-op, not a 500.
    res = await client.post(
        "/api/v1/auth/me/avatar",
        headers=account["headers"],
        files=_avatar_files(),
    )
    assert res.status_code == 200, res.text
    assert res.json()["avatar_url"]
    assert res.json()["avatar_url"] != external_url


@pytest.mark.asyncio
async def test_avatar_upload_cannot_target_another_user(client):
    """No user_id param exists on the endpoint or client -- a second user's
    avatar upload can only ever affect their own account."""
    user_a = await _register(client)
    user_b = await _register(client)

    res_a = await client.post("/api/v1/auth/me/avatar", headers=user_a["headers"], files=_avatar_files())
    res_b = await client.post("/api/v1/auth/me/avatar", headers=user_b["headers"], files=_avatar_files())
    assert res_a.status_code == 200 and res_b.status_code == 200

    me_a = await client.get("/api/v1/auth/me", headers=user_a["headers"])
    me_b = await client.get("/api/v1/auth/me", headers=user_b["headers"])
    assert me_a.json()["avatar_url"] != me_b.json()["avatar_url"]
    assert me_a.json()["id"] != me_b.json()["id"]


@pytest.mark.asyncio
async def test_avatar_upload_ignores_foreign_user_id_query_and_form(client):
    """AC8: extra user_id on the query string or form body cannot retarget
    the write -- the handler has no such parameter (OpenAPI + signature)
    and a second user's avatar_url stays untouched."""
    from app.main import app as fastapi_app
    from app.routers.auth import upload_my_avatar

    params = inspect.signature(upload_my_avatar).parameters
    assert "user_id" not in params

    spec = fastapi_app.openapi()
    operation = spec["paths"]["/api/v1/auth/me/avatar"]["post"]
    for param in operation.get("parameters") or []:
        assert param.get("name") != "user_id"
    request_props = (
        operation.get("requestBody", {})
        .get("content", {})
        .get("multipart/form-data", {})
        .get("schema", {})
        .get("properties", {})
    )
    assert "user_id" not in request_props
    assert set(request_props.keys()) <= {"file"}

    user_a = await _register(client)
    user_b = await _register(client)
    me_b_before = await client.get("/api/v1/auth/me", headers=user_b["headers"])
    victim_id = me_b_before.json()["id"]
    assert me_b_before.json()["avatar_url"] in (None, "")

    res = await client.post(
        f"/api/v1/auth/me/avatar?user_id={victim_id}",
        headers=user_a["headers"],
        files=_avatar_files(),
        data={"user_id": victim_id},
    )
    assert res.status_code == 200, res.text
    assert res.json()["id"] == (await client.get("/api/v1/auth/me", headers=user_a["headers"])).json()["id"]
    assert res.json()["id"] != victim_id

    me_b_after = await client.get("/api/v1/auth/me", headers=user_b["headers"])
    assert me_b_after.json()["avatar_url"] in (None, "")


@pytest.mark.asyncio
async def test_avatar_upload_does_not_invoke_ai_image_analysis(client):
    """AC10: personal avatars must not go through get_ai_provider().analyze_image()."""
    import app.services.avatar_service as avatar_mod
    import app.services.photo_service as photo_mod

    tree = ast.parse(Path(avatar_mod.__file__).read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and node.module:
            assert "services.ai" not in node.module
            assert not any(alias.name == "get_ai_provider" for alias in node.names)

    account = await _register(client)
    with (
        patch("app.services.ai.get_ai_provider") as spy_factory,
        patch.object(photo_mod, "get_ai_provider") as spy_photo,
        patch.object(photo_mod, "save_business_photo", new_callable=AsyncMock) as spy_save_photo,
    ):
        res = await client.post(
            "/api/v1/auth/me/avatar",
            headers=account["headers"],
            files=_avatar_files(),
        )
    assert res.status_code == 200, res.text
    spy_factory.assert_not_called()
    spy_photo.assert_not_called()
    spy_save_photo.assert_not_called()
    body = res.json()
    assert "ai_analysis" not in body
    assert "sentiment" not in body
