"""S-124 — the auditable predefined-value surface.

`FORMS` is the single place every form's field values live. A journey pulls a
`FormSpec` by key, hands it to `HumanForm.fill_and_submit`, and the driver types
the values in like a human and submits (Enter where `enter_submits`, else the
labelled button). `success` carries the dual oracle: a UI expectation and,
where the submission calls the API, the response schema + status.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from uuid import uuid4

# --- value bank -------------------------------------------------------------

REVIEW_BODY = "Genuinely helpful staff and a clean space. Would come back for the coffee."
REPLY_BODY = "Thanks so much for the kind words — see you next time!"
SUPPORT_ISSUE = "I cannot see my submitted review on the business page after 10 minutes."
REPORT_REASON = "This review contains what looks like copy-pasted spam and a promo link."

DEFAULTS: dict[str, Any] = {
    "full_name": "Evelyn Q. Tester",
    "password": "E2ePassw0rd12",
    "phone": "+919876500123",
    "address_line1": "14 Marina Loop",
    "address_line2": "Unit 5",
    "city": "Chennai",
    "state": "TN",
    "postal_code": "600001",
    "country": "IN",
    "website": "https://example.com",
    "business_email": "e2e-shop@example.com",
    "business_phone": "+919876511122",
    "pan": "ABCDE1234F",
    "review_title": "Solid neighbourhood spot",
    "review_body": REVIEW_BODY,
    "support_name": "Evelyn Tester",
    "support_phone": "+919876500123",
    "support_issue": SUPPORT_ISSUE,
    "report_reason": REPORT_REASON,
    "featured_sku": "featured_7d",
}

ASSET_DIR = Path(__file__).resolve().parent / "assets"
SAMPLE_IMAGE = ASSET_DIR / "sample.png"

# 1x1 transparent PNG (canonical) — written to disk by conftest so file inputs
# have a real path the backend's MIME/size check accepts.
SAMPLE_PNG_BYTES = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
)


def unique_email(role: str) -> str:
    return f"{role}+{uuid4().hex[:12]}@e2e.example.com"


def unique_name(prefix: str) -> str:
    return f"{prefix} {uuid4().hex[:8]}"


# --- catalogue types -------------------------------------------------------


@dataclass(frozen=True)
class FieldValue:
    by: str          # {"label","placeholder","role","aria","text","id","name"}
    name: str        # accessible name / id / attr value to locate by
    value: Any = ""  # str | bool | Path | int
    kind: str = "text"  # {"text","textarea","select","checkbox","file","star","otp"}
    role: str = "textbox"  # only for by == "role"


@dataclass(frozen=True)
class FormSpec:
    route: str          # templated, e.g. "/businesses/{slug}/review"
    form_key: str
    submit_label: str
    enter_submits: bool
    fields: tuple[FieldValue, ...] = ()
    success: dict = field(default_factory=dict)
    # {"url": <regex|None>, "text": <str|None>,
    #  "api": (method, path_regex, status, schema_name) | None}


def _spec(key: str, **kw) -> tuple[str, FormSpec]:
    return key, FormSpec(form_key=key.split(".", 1)[1], **kw)


# --- FORMS catalogue ------------------------------------------------------
#
# Keyed "<area>.<form_key>". `fields` use predefined values from DEFAULTS so the
# per-page values are all editable here. Locator names must match live copy —
# the `test_selectors_smoke` canary locks them.

FORMS: dict[str, FormSpec] = dict(
    [
        # ---- anonymous / public ----
        _spec(
            "anon.search_bar",
            route="/",
            submit_label="Search",
            enter_submits=True,
            fields=(FieldValue("placeholder", "Try café, salon, pharmacy, Chrompet", "cafe"),),
            success={"url": r"/search\?.*q=cafe", "text": None, "api": None},
        ),
        _spec(
            "anon.filter_panel",
            route="/search",
            submit_label="Apply filters",
            enter_submits=True,
            fields=(
                FieldValue("name", "city", DEFAULTS["city"], "text"),
                FieldValue("name", "category", "", "select"),
                FieldValue("name", "sort", "rating", "select"),
                FieldValue("name", "min_rating", "", "select"),
            ),
            success={"url": r"/search\?", "text": None, "api": None},
        ),
        _spec(
            "anon.forgot_password",
            route="/forgot-password",
            submit_label="Send reset link",
            enter_submits=True,
            fields=(FieldValue("placeholder", "Email", "nobody-here@e2e.example.com", "text"),),
            success={"url": None, "text": "Check your email", "api": ("POST", r"/auth/forgot-password", 200, None)},
        ),
        _spec(
            "anon.support_ticket",
            route="/support",
            submit_label="Submit",
            enter_submits=False,  # terminated by the "Issue" textarea
            fields=(
                FieldValue("label", "Name", DEFAULTS["support_name"], "text"),
                FieldValue("label", "Phone", DEFAULTS["support_phone"], "text"),
                FieldValue("label", "Issue", DEFAULTS["support_issue"], "textarea"),
            ),
            success={"url": None, "text": "Ticket submitted", "api": ("POST", r"/support-tickets", 201, "SupportTicketResponse")},
        ),
        # ---- customer ----
        _spec(
            "customer.review",
            route="/businesses/{slug}/review",
            submit_label="Post review",
            enter_submits=False,  # terminated by the body textarea
            fields=(
                FieldValue("aria", "5 stars", None, "star"),
                FieldValue("placeholder", "Title (optional)", DEFAULTS["review_title"], "text"),
                FieldValue(
                    "placeholder",
                    "Share details of your experience (min 10 characters)",
                    DEFAULTS["review_body"],
                    "textarea",
                ),
            ),
            success={
                "url": None,
                "text": "Your review is live",
                "api": ("POST", r"/reviews\b", 201, "ReviewResponse"),
            },
        ),
        _spec(
            "customer.review_title_enter",
            route="/businesses/{slug}/review",
            submit_label="Post review",
            enter_submits=True,  # AC2: Enter from the title input submits the <form>
            fields=(
                FieldValue("aria", "5 stars", None, "star"),
                FieldValue(
                    "placeholder",
                    "Share details of your experience (min 10 characters)",
                    DEFAULTS["review_body"],
                    "textarea",
                ),
                FieldValue("placeholder", "Title (optional)", DEFAULTS["review_title"], "text"),
            ),
            success={
                "url": None,
                "text": "Your review is live",
                "api": ("POST", r"/reviews\b", 201, "ReviewResponse"),
            },
        ),
        _spec(
            "customer.profile_basics",
            route="/profile",
            submit_label="Save changes",
            enter_submits=True,
            fields=(
                FieldValue("id", "full_name", DEFAULTS["full_name"], "text"),
                FieldValue("id", "phone", DEFAULTS["phone"], "text"),
                FieldValue("placeholder", "Address line 1", DEFAULTS["address_line1"], "text"),
                FieldValue("placeholder", "City", DEFAULTS["city"], "text"),
                FieldValue("placeholder", "State", DEFAULTS["state"], "text"),
                FieldValue("placeholder", "Postal code", DEFAULTS["postal_code"], "text"),
            ),
            success={"url": None, "text": "Profile updated", "api": ("PATCH", r"/auth/me", 200, "UserResponse")},
        ),
        # ---- merchant ----
        _spec(
            "merchant.national_id",
            route="/merchant/dashboard",
            submit_label="Save national ID",
            enter_submits=True,
            fields=(
                FieldValue("aria", "National ID type", "pan", "select"),
                FieldValue("aria", "National ID number", DEFAULTS["pan"], "text"),
                FieldValue("aria", "Confirm with password", DEFAULTS["password"], "text"),
            ),
            success={"url": None, "text": None, "api": ("PATCH", r"/auth/me", 200, "UserResponse")},
        ),
        _spec(
            "merchant.business_create",
            route="/merchant/businesses/new",
            submit_label="Submit for approval",
            enter_submits=True,  # AC 6b: BusinessForm submitted with Enter
            fields=(
                # BusinessForm marks required labels with a ★ span — the bare word
                # "City" also substring-matches the Country <select> a11y name
                # (option list contains "…City").
                FieldValue("label", "Business name ★", "{name}", "text"),
                FieldValue("label", "Street address ★", DEFAULTS["address_line1"], "text"),
                FieldValue("label", "City ★", DEFAULTS["city"], "text"),
                FieldValue("label", "Phone ★", DEFAULTS["business_phone"], "text"),
                FieldValue("label", "Email ★", DEFAULTS["business_email"], "text"),
            ),
            success={
                "url": r"/merchant/dashboard",
                "text": None,
                "api": ("POST", r"/businesses\b", 201, "BusinessResponse"),
            },
        ),
        _spec(
            "merchant.reply",
            route="/merchant/dashboard",
            submit_label="Post reply",
            enter_submits=False,  # response textarea
            fields=(
                FieldValue("placeholder", "Write a response to this review", REPLY_BODY, "textarea"),
            ),
            success={
                "url": None,
                "text": None,
                "api": ("POST", r"/reviews/[^/]+/reply", 201, "ReplyResponse"),
            },
        ),
        # ---- admin ----
        _spec(
            "admin.category_create",
            route="/admin",
            submit_label="Add category",
            enter_submits=True,
            fields=(FieldValue("placeholder", "New category name", "{name}", "text"),),
            success={"url": None, "text": None, "api": ("POST", r"/businesses/categories", 201, None)},
        ),
    ]
)


# Forms whose submission belongs to a multi-step wizard driven explicitly by the
# journey (not via a single fill_and_submit) — excluded from the coverage guard's
# "exercised" expectation because the wizard function marks them.
WIZARD_KEYS = {
    "anon.login",
    "anon.register",
    "anon.register_phone_otp",
    "anon.reset_password",
    "anon.collect_inline_auth",
    "merchant.business_edit_address_otp",
}


def all_form_keys() -> set[str]:
    return set(FORMS) | WIZARD_KEYS
