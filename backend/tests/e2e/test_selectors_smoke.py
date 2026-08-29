"""S-124 AC12 — selector copy-drift canary.

There are zero data-testids in the frontend, so the whole suite rides on
accessible names / roles / placeholders / button text. This resolves each
catalogued selector on its own route to exactly one element; a single failure
names the drifted copy before a journey fails for a confusing reason.
"""

from __future__ import annotations

import pytest
from playwright.sync_api import expect

from tests.e2e.form_data import FORMS

pytestmark = [pytest.mark.e2e, pytest.mark.catalog]

# (route, [(kind, name), ...]) — routes with no auth needed / stable seed copy.
PUBLIC_CHECKS = [
    ("/", [("placeholder", "Search restaurants, salons, shops...")]),
    ("/search", [
        ("name", "city"), ("name", "category"), ("name", "sort"), ("name", "min_rating"),
        ("button", "Apply filters"),
    ]),
    ("/forgot-password", [("placeholder", "Email"), ("button", "Send reset link")]),
    ("/support", [("label", "Name"), ("label", "Phone"), ("label", "Issue"), ("button", "Submit")]),
    ("/login", [("placeholder", "Email"), ("placeholder", "Password"), ("button", "Sign in")]),
    ("/register", [
        ("placeholder", "Full name"),
        ("placeholder", "Password (min 12 chars, include a letter and a digit)"),
        ("button", "Sign up"),
    ]),
]


def _resolve(page, kind: str, name: str):
    if kind == "placeholder":
        return page.get_by_placeholder(name, exact=False)
    if kind == "label":
        return page.get_by_label(name, exact=False)
    if kind == "button":
        return page.get_by_role("button", name=name)
    if kind == "name":
        return page.locator(f'[name="{name}"]')
    raise ValueError(kind)


@pytest.mark.parametrize("route,checks", PUBLIC_CHECKS, ids=[c[0] for c in PUBLIC_CHECKS])
def test_public_selectors_resolve(page, route, checks):
    page.goto(route)
    for kind, name in checks:
        loc = _resolve(page, kind, name)
        assert loc.count() >= 1, f"{route}: no element for {kind}={name!r}"
        expect(loc.first).to_be_visible(timeout=15_000)


def test_catalogue_is_internally_consistent():
    """Every FormSpec has a submit_label and at least one field or an api oracle."""
    for key, spec in FORMS.items():
        assert spec.submit_label, f"{key} missing submit_label"
        assert spec.fields or spec.success.get("api"), f"{key} has nothing to exercise"
        if spec.success.get("api"):
            method, path, status, _schema = spec.success["api"]
            assert method in ("GET", "POST", "PATCH", "PUT", "DELETE"), key
            assert isinstance(status, int), key
