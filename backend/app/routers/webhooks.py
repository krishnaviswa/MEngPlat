"""Meta WhatsApp Cloud API webhook (unauthenticated; HMAC required)."""

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import PlainTextResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import WhatsAppWebhookAck
from app.services.whatsapp import get_whatsapp_provider
from app.services.whatsapp_ingest_service import handle_inbound

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])


@router.get("/whatsapp")
async def whatsapp_verify(
    hub_mode: str | None = Query(default=None, alias="hub.mode"),
    hub_verify_token: str | None = Query(default=None, alias="hub.verify_token"),
    hub_challenge: str | None = Query(default=None, alias="hub.challenge"),
) -> PlainTextResponse:
    """Meta subscription handshake — echo `hub.challenge` when the verify token matches."""
    provider = get_whatsapp_provider()
    if not provider.verify_webhook_challenge(hub_mode, hub_verify_token):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verification failed")
    return PlainTextResponse(hub_challenge or "")


@router.post("/whatsapp", response_model=WhatsAppWebhookAck)
async def whatsapp_inbound(
    request: Request,
    db: AsyncSession = Depends(get_db),
    x_hub_signature_256: str | None = Header(default=None),
) -> WhatsAppWebhookAck:
    """Inbound WhatsApp messages. Unauthenticated; `X-Hub-Signature-256` HMAC required."""
    body = await request.body()
    if not x_hub_signature_256:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing signature")
    result = await handle_inbound(db, body, x_hub_signature_256)
    return WhatsAppWebhookAck(**result)
