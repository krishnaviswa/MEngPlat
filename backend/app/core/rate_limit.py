from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address


def _client_ip_key(request: Request) -> str:
    # Railway (and most PaaS) terminate TLS at an edge proxy, so
    # request.client.host is the proxy's IP, not the caller's -- every
    # request would collapse onto one rate-limit bucket. uvicorn isn't run
    # with --proxy-headers (that trusts the header globally, a bigger blast
    # radius than this needs), so read it narrowly, just for this key.
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return get_remote_address(request)


# In-memory storage: this app runs as a single backend instance (see
# README's deployment section), so per-process limits are equivalent to
# global ones without adding a hard Redis dependency to the login path --
# app/services/cache.py's whole design is that Redis stays optional.
limiter = Limiter(key_func=_client_ip_key)
