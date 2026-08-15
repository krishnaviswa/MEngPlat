"""Pydantic technical oracle helpers for Playwright APIRequestContext payloads."""

from __future__ import annotations

from app.schemas import BusinessResponse


def validate_business_list(payload: object) -> list[BusinessResponse]:
    if not isinstance(payload, list):
        raise AssertionError(f"expected list of businesses, got {type(payload).__name__}")
    return [BusinessResponse.model_validate(item) for item in payload]
