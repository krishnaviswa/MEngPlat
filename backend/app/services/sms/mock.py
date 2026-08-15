"""Local/demo SMS — logs the OTP so Compose works with no vendor spend."""

import logging

logger = logging.getLogger("app.sms.mock")


class MockSmsProvider:
    name = "mock"

    async def send_otp(self, phone: str, code: str) -> None:
        logger.info("MOCK SMS OTP to=%s code=%s", phone, code)
