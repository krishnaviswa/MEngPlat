"""Msg91 OTP adapter. Auth key stays in env."""

import logging

import httpx

from app.config import get_settings

logger = logging.getLogger("app.sms.msg91")


class Msg91SmsProvider:
    name = "msg91"

    async def send_otp(self, phone: str, code: str) -> None:
        settings = get_settings()
        mobile = phone.lstrip("+")
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                "https://control.msg91.com/api/v5/otp",
                params={
                    "template_id": settings.msg91_template_id,
                    "mobile": mobile,
                    "otp": code,
                },
                headers={"authkey": settings.msg91_auth_key, "accept": "application/json"},
            )
            response.raise_for_status()
