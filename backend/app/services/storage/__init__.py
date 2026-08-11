import asyncio
import uuid
from pathlib import Path
from typing import Protocol

import boto3
from fastapi import UploadFile

from app.config import get_settings

settings = get_settings()


class StorageProvider(Protocol):
    async def save(self, file: UploadFile, folder: str) -> str: ...

    async def delete(self, url: str) -> None: ...


class LocalStorageProvider:
    def __init__(self) -> None:
        self.base_path = Path(settings.storage_local_path)
        self.base_path.mkdir(parents=True, exist_ok=True)

    async def save(self, file: UploadFile, folder: str) -> str:
        folder_path = self.base_path / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        ext = Path(file.filename or "file.jpg").suffix or ".jpg"
        filename = f"{uuid.uuid4()}{ext}"
        dest = folder_path / filename
        content = await file.read()
        dest.write_bytes(content)
        return f"/uploads/{folder}/{filename}"

    async def delete(self, url: str) -> None:
        relative = url.removeprefix("/uploads/")
        path = self.base_path / relative
        if path.exists():
            path.unlink()


class S3StorageProvider:
    """Amazon S3, via boto3's default credential chain (env vars, IAM role, ~/.aws/credentials)."""

    def __init__(self) -> None:
        if not settings.storage_s3_bucket:
            raise RuntimeError("STORAGE_S3_BUCKET must be set when STORAGE_PROVIDER=s3")
        self.bucket = settings.storage_s3_bucket
        endpoint = settings.storage_s3_endpoint_url.rstrip("/")
        self.public_base_url = settings.storage_s3_public_base_url.rstrip("/") or (
            f"{endpoint}/{self.bucket}"
            if endpoint
            else f"https://{self.bucket}.s3.{settings.storage_s3_region}.amazonaws.com"
        )
        self._client = boto3.client(
            "s3",
            region_name=settings.storage_s3_region,
            endpoint_url=endpoint or None,
        )

    async def save(self, file: UploadFile, folder: str) -> str:
        ext = Path(file.filename or "file.jpg").suffix or ".jpg"
        key = f"{folder}/{uuid.uuid4()}{ext}"
        content = await file.read()
        # boto3 is sync; offload so it doesn't block the event loop.
        await asyncio.to_thread(
            self._client.put_object,
            Bucket=self.bucket,
            Key=key,
            Body=content,
            ContentType=file.content_type or "application/octet-stream",
        )
        return f"{self.public_base_url}/{key}"

    async def delete(self, url: str) -> None:
        key = url.removeprefix(f"{self.public_base_url}/")
        await asyncio.to_thread(self._client.delete_object, Bucket=self.bucket, Key=key)


class AzureBlobStorageProvider:
    """Placeholder for Azure Blob Storage — implement with azure-storage-blob in production."""

    async def save(self, file: UploadFile, folder: str) -> str:
        raise NotImplementedError("Azure storage not configured. Set STORAGE_PROVIDER=local for development.")

    async def delete(self, url: str) -> None:
        raise NotImplementedError("Azure storage not configured.")


def get_storage_provider() -> StorageProvider:
    if settings.storage_provider == "s3":
        return S3StorageProvider()
    if settings.storage_provider == "azure":
        return AzureBlobStorageProvider()
    return LocalStorageProvider()
