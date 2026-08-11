"""Storage abstraction: provider selection + the S3 provider's key/URL handling.

No real AWS calls -- boto3.client is monkeypatched to a stand-in that records
what it was called with. LocalStorageProvider already has implicit coverage
via test_s011_s016_batch.py's photo upload flow, so this file focuses on the
S3 provider and the factory's branching.
"""

import io

import pytest
from starlette.datastructures import Headers
from fastapi import UploadFile

from app.services import storage as storage_module
from app.services.storage import LocalStorageProvider, S3StorageProvider, get_storage_provider


class FakeS3Client:
    def __init__(self):
        self.put_calls = []
        self.delete_calls = []

    def put_object(self, **kwargs):
        self.put_calls.append(kwargs)

    def delete_object(self, **kwargs):
        self.delete_calls.append(kwargs)


@pytest.fixture
def fake_boto_client(monkeypatch):
    fake = FakeS3Client()
    monkeypatch.setattr(storage_module.boto3, "client", lambda *a, **kw: fake)
    return fake


def make_upload_file(filename: str, content: bytes, content_type: str) -> UploadFile:
    headers = Headers({"content-type": content_type})
    return UploadFile(file=io.BytesIO(content), filename=filename, headers=headers)


def test_get_storage_provider_defaults_to_local():
    assert isinstance(get_storage_provider(), LocalStorageProvider)


def test_get_storage_provider_returns_s3_when_configured(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_provider", "s3")
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    assert isinstance(get_storage_provider(), S3StorageProvider)


def test_s3_provider_requires_bucket(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "")
    with pytest.raises(RuntimeError, match="STORAGE_S3_BUCKET"):
        S3StorageProvider()


def test_s3_provider_default_url_is_virtual_hosted_style(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    monkeypatch.setattr(storage_module.settings, "storage_s3_region", "eu-west-1")
    monkeypatch.setattr(storage_module.settings, "storage_s3_endpoint_url", "")
    monkeypatch.setattr(storage_module.settings, "storage_s3_public_base_url", "")
    provider = S3StorageProvider()
    assert provider.public_base_url == "https://test-bucket.s3.eu-west-1.amazonaws.com"


def test_s3_provider_public_base_url_override_wins(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    monkeypatch.setattr(storage_module.settings, "storage_s3_public_base_url", "https://cdn.example.com/")
    provider = S3StorageProvider()
    assert provider.public_base_url == "https://cdn.example.com"


def test_s3_provider_endpoint_url_used_for_s3_compatible_services(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    monkeypatch.setattr(storage_module.settings, "storage_s3_endpoint_url", "http://localhost:9000")
    monkeypatch.setattr(storage_module.settings, "storage_s3_public_base_url", "")
    provider = S3StorageProvider()
    assert provider.public_base_url == "http://localhost:9000/test-bucket"


@pytest.mark.asyncio
async def test_s3_provider_save_uploads_and_returns_url(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    monkeypatch.setattr(storage_module.settings, "storage_s3_region", "us-east-1")
    monkeypatch.setattr(storage_module.settings, "storage_s3_endpoint_url", "")
    monkeypatch.setattr(storage_module.settings, "storage_s3_public_base_url", "")
    provider = S3StorageProvider()

    upload = make_upload_file("photo.png", b"binary-data", "image/png")
    url = await provider.save(upload, "photos")

    assert len(fake_boto_client.put_calls) == 1
    call = fake_boto_client.put_calls[0]
    assert call["Bucket"] == "test-bucket"
    assert call["Key"].startswith("photos/")
    assert call["Key"].endswith(".png")
    assert call["Body"] == b"binary-data"
    assert call["ContentType"] == "image/png"
    assert url == f"https://test-bucket.s3.us-east-1.amazonaws.com/{call['Key']}"


@pytest.mark.asyncio
async def test_s3_provider_delete_extracts_key_from_url(monkeypatch, fake_boto_client):
    monkeypatch.setattr(storage_module.settings, "storage_s3_bucket", "test-bucket")
    monkeypatch.setattr(storage_module.settings, "storage_s3_region", "us-east-1")
    monkeypatch.setattr(storage_module.settings, "storage_s3_endpoint_url", "")
    monkeypatch.setattr(storage_module.settings, "storage_s3_public_base_url", "")
    provider = S3StorageProvider()

    url = "https://test-bucket.s3.us-east-1.amazonaws.com/photos/abc123.png"
    await provider.delete(url)

    assert fake_boto_client.delete_calls == [{"Bucket": "test-bucket", "Key": "photos/abc123.png"}]
