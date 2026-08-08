"""One shared httpx.AsyncClient for every AI HTTP call.

Building a fresh client per call -- what every provider did before this --
throws away the TLS handshake and connection pool on every single request.
Created lazily and closed from main.py's lifespan on shutdown.
"""

import httpx

_client: httpx.AsyncClient | None = None


def get_shared_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        _client = httpx.AsyncClient(timeout=60.0)
    return _client


async def close_shared_client() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None
