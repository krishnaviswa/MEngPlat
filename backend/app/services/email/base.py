"""The contract every email provider implements. Mirrors app/services/storage's Protocol shape."""

from typing import Protocol


class EmailProvider(Protocol):
    async def send(self, to: str, subject: str, text: str, html: str | None = None) -> None: ...
