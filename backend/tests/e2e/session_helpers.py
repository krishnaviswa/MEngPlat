"""S-124 — browser session helpers shared by conftest fixtures and journeys."""

from __future__ import annotations


def inject_session(page, frontend_url: str, access: str, refresh: str | None) -> None:
    """Put a real session into the browser without driving the login UI — avoids a
    login-storm (and the /auth rate limits) across dozens of authed tests. The
    dedicated wizard tests still exercise the real login/register flows.
    """
    page.goto(frontend_url + "/")
    page.evaluate(
        "([a, r]) => { localStorage.setItem('access_token', a);"
        " if (r) localStorage.setItem('refresh_token', r); }",
        [access, refresh or ""],
    )
