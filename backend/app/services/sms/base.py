"""SMS provider contract. Routers never import Msg91."""

from typing import Protocol


class SmsProvider(Protocol):
    name: str

    async def send_otp(self, phone: str, code: str) -> None: ...
