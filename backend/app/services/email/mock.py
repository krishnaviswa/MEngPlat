"""Local/demo email provider -- logs only, no vendor network call, no DB outbox."""

import logging

logger = logging.getLogger("app.email.mock")


class MockEmailProvider:
    async def send(self, to: str, subject: str, text: str, html: str | None = None) -> None:
        logger.info("MOCK EMAIL to=%s subject=%r body=%s", to, subject, text)
