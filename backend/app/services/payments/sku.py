"""SKU constants for the single featured-week product (S-036)."""

FEATURED_SKU_CODE = "featured_7d"
FEATURED_DURATION_DAYS = 7
FEATURED_LISTED_PRICE_INR = 499
FEATURED_AMOUNT_PAISE = 49900
FEATURED_CURRENCY = "INR"

# ~2% + 18% GST on the gateway cut when the webhook omits `fee` (mock / incomplete payload).
MOCK_GATEWAY_FEE_PAISE = round(FEATURED_AMOUNT_PAISE * 0.02 * 1.18)


def split_fees(amount_captured_paise: int, gateway_fee_paise: int | None) -> tuple[int, int]:
    """Return (platform_fee_paise, gateway_fee_paise). Sums to captured amount on paid."""
    gateway = MOCK_GATEWAY_FEE_PAISE if gateway_fee_paise is None else gateway_fee_paise
    gateway = max(0, min(gateway, amount_captured_paise))
    return amount_captured_paise - gateway, gateway


def sku_payload() -> dict:
    return {
        "code": FEATURED_SKU_CODE,
        "duration_days": FEATURED_DURATION_DAYS,
        "listed_price_inr": FEATURED_LISTED_PRICE_INR,
    }
