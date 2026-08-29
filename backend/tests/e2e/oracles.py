"""Pydantic technical oracle helpers for Playwright APIRequestContext payloads.

The oracle for an endpoint is always the backend's own Pydantic response model
(`app/schemas`) — reusing it means the check breaks the moment backend and test
drift apart, instead of the two silently diverging.
"""

from __future__ import annotations

from app.schemas import (
    BusinessReportResponse,
    BusinessResponse,
    DashboardStats,
    FeaturedCheckoutResponse,
    PlatformAnalytics,
    ReplyResponse,
    ReviewResponse,
    SupportTicketResponse,
    UserResponse,
)


def validate_business_list(payload: object) -> list[BusinessResponse]:
    if not isinstance(payload, list):
        raise AssertionError(f"expected list of businesses, got {type(payload).__name__}")
    return [BusinessResponse.model_validate(item) for item in payload]


def validate_business(payload: object) -> BusinessResponse:
    return BusinessResponse.model_validate(payload)


def validate_review(payload: object) -> ReviewResponse:
    return ReviewResponse.model_validate(payload)


def validate_review_list(payload: object) -> list[ReviewResponse]:
    if not isinstance(payload, list):
        raise AssertionError(f"expected list of reviews, got {type(payload).__name__}")
    return [ReviewResponse.model_validate(item) for item in payload]


def validate_reply(payload: object) -> ReplyResponse:
    return ReplyResponse.model_validate(payload)


def validate_user(payload: object) -> UserResponse:
    return UserResponse.model_validate(payload)


def validate_dashboard_stats(payload: object) -> DashboardStats:
    return DashboardStats.model_validate(payload)


def validate_platform_analytics(payload: object) -> PlatformAnalytics:
    return PlatformAnalytics.model_validate(payload)


def validate_support_ticket(payload: object) -> SupportTicketResponse:
    return SupportTicketResponse.model_validate(payload)


def validate_business_report(payload: object) -> BusinessReportResponse:
    return BusinessReportResponse.model_validate(payload)


def validate_featured_checkout(payload: object) -> FeaturedCheckoutResponse:
    return FeaturedCheckoutResponse.model_validate(payload)


SCHEMA_ORACLES = {
    "BusinessResponse": validate_business,
    "BusinessList": validate_business_list,
    "ReviewResponse": validate_review,
    "ReviewList": validate_review_list,
    "ReplyResponse": validate_reply,
    "UserResponse": validate_user,
    "DashboardStats": validate_dashboard_stats,
    "PlatformAnalytics": validate_platform_analytics,
    "SupportTicketResponse": validate_support_ticket,
    "BusinessReportResponse": validate_business_report,
    "FeaturedCheckoutResponse": validate_featured_checkout,
}
