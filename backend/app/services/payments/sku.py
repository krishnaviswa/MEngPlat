"""Featured SKU catalog (S-042). Three listing-boost products; paise only in the ledger."""

FEATURED_CURRENCY = "INR"

FEATURED_SKUS: dict[str, dict] = {
    "featured_7d": {
        "code": "featured_7d",
        "duration_days": 7,
        "listed_price_inr": 299,
        "amount_paise": 29900,
    },
    "featured_15d": {
        "code": "featured_15d",
        "duration_days": 15,
        "listed_price_inr": 499,
        "amount_paise": 49900,
    },
    "featured_30d": {
        "code": "featured_30d",
        "duration_days": 30,
        "listed_price_inr": 899,
        "amount_paise": 89900,
    },
}

DEFAULT_SKU_CODE = "featured_7d"


class UnknownSkuError(KeyError):
    pass


def get_sku(code: str) -> dict:
    sku = FEATURED_SKUS.get(code)
    if sku is None:
        raise UnknownSkuError(code)
    return sku


def catalog() -> list[dict]:
    return [dict(v) for v in FEATURED_SKUS.values()]


def sku_payload(code: str = DEFAULT_SKU_CODE) -> dict:
    sku = get_sku(code)
    return {
        "code": sku["code"],
        "duration_days": sku["duration_days"],
        "listed_price_inr": sku["listed_price_inr"],
    }


def mock_gateway_fee_paise(amount_paise: int) -> int:
    """~2% + 18% GST on the gateway cut when the webhook omits `fee`."""
    return round(amount_paise * 0.02 * 1.18)


def split_fees(amount_captured_paise: int, gateway_fee_paise: int | None) -> tuple[int, int]:
    """Return (platform_fee_paise, gateway_fee_paise). Sums to captured amount on paid."""
    gateway = mock_gateway_fee_paise(amount_captured_paise) if gateway_fee_paise is None else gateway_fee_paise
    gateway = max(0, min(gateway, amount_captured_paise))
    return amount_captured_paise - gateway, gateway
