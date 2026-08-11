"""Rate limiter: the X-Forwarded-For-aware key function, and that the limit
actually trips. Uses a throwaway FastAPI app wired the same way main.py wires
the real one -- never imports app.main, so this never touches a real DB.

The throwaway app is built exactly once at module scope. `@limiter.limit(...)`
registers each limit keyed by the endpoint function's `__module__.__name__`;
rebuilding the app (and its identically-named nested route functions) per
test would re-register the same key against the shared `limiter` singleton
and double-count hits. One app, reused across tests; only the limiter's
in-memory counters get reset between tests.
"""

import pytest
from fastapi import FastAPI, Request
from httpx import ASGITransport, AsyncClient
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.rate_limit import _client_ip_key, limiter

_app = FastAPI()
_app.state.limiter = limiter
_app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
_app.add_middleware(SlowAPIMiddleware)


@_app.get("/whoami")
def _whoami(request: Request):
    return {"key": _client_ip_key(request)}


@_app.get("/limited")
@limiter.limit("2/minute")
def _limited(request: Request):
    return {"ok": True}


@pytest.fixture
async def client():
    limiter.reset()
    transport = ASGITransport(app=_app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_key_uses_first_x_forwarded_for_entry(client):
    response = await client.get("/whoami", headers={"X-Forwarded-For": "203.0.113.5, 10.0.0.1"})
    assert response.json()["key"] == "203.0.113.5"


@pytest.mark.asyncio
async def test_key_falls_back_to_client_host_without_forwarded_header(client):
    response = await client.get("/whoami")
    # httpx's ASGITransport synthesizes a fixed peer address for the client.
    assert response.json()["key"] == "127.0.0.1"


@pytest.mark.asyncio
async def test_third_request_from_same_ip_is_rate_limited(client):
    headers = {"X-Forwarded-For": "198.51.100.9"}
    first = await client.get("/limited", headers=headers)
    second = await client.get("/limited", headers=headers)
    third = await client.get("/limited", headers=headers)

    assert first.status_code == 200
    assert second.status_code == 200
    assert third.status_code == 429


@pytest.mark.asyncio
async def test_different_ips_get_independent_limits(client):
    a = {"X-Forwarded-For": "198.51.100.10"}
    b = {"X-Forwarded-For": "198.51.100.11"}

    await client.get("/limited", headers=a)
    await client.get("/limited", headers=a)
    exhausted_a = await client.get("/limited", headers=a)
    still_ok_b = await client.get("/limited", headers=b)

    assert exhausted_a.status_code == 429
    assert still_ok_b.status_code == 200
