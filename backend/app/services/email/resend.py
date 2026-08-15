"""Resend HTTP API adapter. Routers never import this directly -- use get_email_provider()."""

import httpx

from app.config import get_settings

RESEND_API_URL = "https://api.resend.com/emails"


class ResendEmailProvider:
    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.resend_api_key
        self.from_email = settings.email_from

    async def send(self, to: str, subject: str, text: str, html: str | None = None) -> None:
        payload: dict[str, str | list[str]] = {
            "from": self.from_email,
            "to": [to],
            "subject": subject,
            "text": text,
        }
        if html:
            payload["html"] = html
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                RESEND_API_URL,
                json=payload,
                headers={"Authorization": f"Bearer {self.api_key}"},
            )
            response.raise_for_status()
