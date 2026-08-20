from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Receive, Scope, Send


class SecurityHeadersMiddleware:
    """Attach baseline security headers. HSTS only when the request is HTTPS
    (including behind a TLS-terminating proxy via X-Forwarded-Proto) so local
    Compose HTTP is not broken by a preload-style policy.

    Pure ASGI (not BaseHTTPMiddleware) so asyncpg sessions are not used from a
    Starlette TaskGroup — that combination raises "another operation is in progress".
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_headers(message: dict) -> None:
            if message["type"] == "http.response.start":
                headers = MutableHeaders(raw=message.setdefault("headers", []))
                headers["X-Content-Type-Options"] = "nosniff"
                headers["X-Frame-Options"] = "DENY"
                headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
                headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=(self)"
                proto = "http"
                for key, value in scope.get("headers") or []:
                    if key == b"x-forwarded-proto":
                        proto = value.decode("latin-1")
                        break
                if proto == "https" or scope.get("scheme") == "https":
                    headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
            await send(message)

        await self.app(scope, receive, send_with_headers)
