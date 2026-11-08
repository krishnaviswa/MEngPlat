"""wf-suspend — admin suspends a customer in the panel -> that customer can no longer sign in."""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD
from tests.e2e.form_data import unique_email
from tests.e2e.pages.admin_panel import AdminPanelPage
from tests.e2e.pages.login import LoginPage

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_suspend(wf, api):
    email = unique_email("customer")
    user = api.register(email, role="customer", password=PASSWORD)
    admin_token = wf.token("admin")
    try:
        # 1. admin suspends exactly this fresh user (never a seeded account)
        admin = wf.actor("admin")
        panel = AdminPanelPage(admin)
        wf.visit(admin, "/admin", ready=admin.get_by_role("heading", name="Admin Panel"), label="/admin")
        admin.get_by_role("button", name="Total users").click()
        panel.toggle_user(email, "Suspend")
        wf.scan(admin, "/admin after suspend")

        # 2. the suspended user cannot sign in through the real login page
        anon = wf.anon()
        login = LoginPage(anon)
        wf.visit(anon, "/login", ready=anon.get_by_role("button", name="Sign in"), label="/login")
        login.submit_credentials(email, PASSWORD)
        expect(anon.get_by_text(re.compile("suspend", re.I)).first).to_be_visible(timeout=20_000)
        expect(anon).to_have_url(re.compile(r"/login"))
        expect(anon.get_by_role("heading", name="Authenticator code")).to_have_count(0)
        expect(anon.get_by_role("heading", name="Set up authenticator")).to_have_count(0)
        assert anon.evaluate("() => localStorage.getItem('access_token')") is None
    finally:
        api.reactivate_user(admin_token, user.id)
