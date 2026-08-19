"""GET /auth/google-config — public Web OAuth client ID for native sign-in."""

from app.routers.auth import google_config


class _Settings:
    def __init__(self, client_id: str):
        self.google_client_id = client_id


def test_google_config_returns_web_client_id(monkeypatch):
    monkeypatch.setattr("app.routers.auth.get_settings", lambda: _Settings("web-client.apps.googleusercontent.com"))
    assert google_config().client_id == "web-client.apps.googleusercontent.com"


def test_google_config_empty_when_unset(monkeypatch):
    monkeypatch.setattr("app.routers.auth.get_settings", lambda: _Settings(""))
    assert google_config().client_id == ""
