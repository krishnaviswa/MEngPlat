"""S-035 AC 5 / AC 7: the three v1 templates are transactional-only event
copy -- no marketing/promo/digest/subscribe language, and no AI-derived text
(sentiment, suggested reply, insights) anywhere in a rendered body.

Mostly code-inspection assertions per the slice's own framing of AC 5 ("Tester
inspects templates and triggers") -- encoded here as tests so a future edit
that slips marketing or AI copy into a template fails CI instead of only
being caught by a human re-reading the file.
"""

import inspect

from app.services.email.templates import (
    listing_approved_email,
    new_review_email,
    password_reset_email,
)

# Words that would signal this stopped being a transactional-only send.
MARKETING_MARKERS = [
    "unsubscribe",
    "newsletter",
    "digest",
    "% off",
    "promo",
    "sale",
    "subscribe",
    "marketing",
    "campaign",
    "weekly roundup",
    "daily roundup",
]

# Words that would signal AI-generated content leaked into v1 copy (AC 7).
AI_MARKERS = [
    "sentiment",
    "ai-generated",
    "ai generated",
    "suggested response",
    "suggested reply",
    "insight",
    "summary of your reviews",
    "our ai",
]


def _rendered_bodies() -> list[tuple[str, str, str]]:
    """(template_name, subject, text) for all three v1 templates with
    representative inputs."""
    reset_subject, reset_text = password_reset_email("raw-token-abc123")
    approved_subject, approved_text = listing_approved_email("Joe's Diner")
    review_subject, review_text = new_review_email("Joe's Diner", 4)
    return [
        ("password_reset", reset_subject, reset_text),
        ("listing_approved", approved_subject, approved_text),
        ("new_review", review_subject, review_text),
    ]


def test_no_marketing_or_campaign_language_in_any_template():
    for name, subject, text in _rendered_bodies():
        combined = f"{subject}\n{text}".lower()
        for marker in MARKETING_MARKERS:
            assert marker not in combined, f"{name} template contains marketing marker {marker!r}"


def test_no_ai_derived_language_in_any_template():
    for name, subject, text in _rendered_bodies():
        combined = f"{subject}\n{text}".lower()
        for marker in AI_MARKERS:
            assert marker not in combined, f"{name} template contains AI-derived marker {marker!r}"


def test_password_reset_email_contains_link_and_one_hour_one_use_expiry_note():
    subject, text = password_reset_email("raw-token-abc123")
    assert "raw-token-abc123" in text
    assert "reset-password?token=raw-token-abc123" in text
    assert "1 hour" in text
    assert "once" in text
    assert "reset" in subject.lower()


def test_listing_approved_email_contains_business_name_and_live_copy():
    subject, text = listing_approved_email("Joe's Diner")
    assert "Joe's Diner" in subject
    assert "Joe's Diner" in text
    assert "live" in text.lower()


def test_new_review_email_contains_business_name_and_optional_star_rating():
    subject, text = new_review_email("Joe's Diner", 5)
    assert "Joe's Diner" in subject
    assert "Joe's Diner" in text
    assert "5-star" in text


def test_new_review_email_omits_rating_note_when_rating_is_none():
    subject, text = new_review_email("Joe's Diner", None)
    assert "-star" not in text
    assert "Joe's Diner" in text


def test_new_review_email_signature_only_accepts_business_name_and_a_plain_rating():
    """Guards AC 7: the call site can only ever pass a business name (str)
    and a plain int rating -- no sentiment/summary/suggested_response
    parameter exists for a caller to plumb AI-derived text through."""
    params = list(inspect.signature(new_review_email).parameters)
    assert params == ["business_name", "rating"]


def test_listing_approved_email_signature_only_accepts_business_name():
    params = list(inspect.signature(listing_approved_email).parameters)
    assert params == ["business_name"]


def test_password_reset_email_signature_only_accepts_a_token():
    params = list(inspect.signature(password_reset_email).parameters)
    assert params == ["token"]
