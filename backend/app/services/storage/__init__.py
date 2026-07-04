import uuid
from pathlib import Path
from typing import Protocol

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
    """Placeholder for Amazon S3 — implement with boto3 in production."""

    async def save(self, file: UploadFile, folder: str) -> str:
        raise NotImplementedError("S3 storage not configured. Set STORAGE_PROVIDER=local for development.")

    async def delete(self, url: str) -> None:
        raise NotImplementedError("S3 storage not configured.")


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
