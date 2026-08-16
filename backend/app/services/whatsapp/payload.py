"""Parse Meta-shaped webhook JSON (shared by mock and meta_cloud)."""

from __future__ import annotations

import json
from typing import Any

from app.services.whatsapp.base import InboundMessage


def loads_json(body: bytes) -> dict[str, Any]:
    return json.loads(body.decode("utf-8"))


def parse_meta_payload(payload: dict[str, Any]) -> list[InboundMessage]:
    messages: list[InboundMessage] = []
    for entry in payload.get("entry") or []:
        for change in entry.get("changes") or []:
            value = change.get("value") or {}
            for msg in value.get("messages") or []:
                messages.append(_one(msg))
    return messages


def _one(msg: dict[str, Any]) -> InboundMessage:
    kind = str(msg.get("type") or "other")
    text = None
    media_id = None
    mime_type = None
    caption = None
    if kind == "text":
        text = str((msg.get("text") or {}).get("body") or "")
    elif kind == "image":
        image = msg.get("image") or {}
        media_id = image.get("id")
        mime_type = image.get("mime_type") or "image/jpeg"
        caption = image.get("caption")
        kind = "image"
    else:
        kind = "other"
    return InboundMessage(
        from_phone=str(msg.get("from") or ""),
        message_id=str(msg.get("id") or ""),
        type=kind,
        text=text,
        media_id=str(media_id) if media_id else None,
        mime_type=mime_type,
        caption=caption,
        raw=msg,
    )
