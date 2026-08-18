"""S-073: GET /maps/autocomplete (app/routers/maps.py) and its backing
`app/services/geo.search_addresses` (AC1/AC2/AC8). Nominatim calls are mocked
with respx -- no live network calls in tests (matches AI_PROVIDER=mock spirit
for external HTTP dependencies)."""

import httpx
import respx

from app.routers.maps import autocomplete_address
from app.services.geo import search_addresses

NOMINATIM_SEARCH_URL = "https://nominatim.openstreetmap.org/search"


@respx.mock
async def test_search_addresses_parses_city_postal_state_from_nominatim():
    respx.get(NOMINATIM_SEARCH_URL).mock(
        return_value=httpx.Response(
            200,
            json=[
                {
                    "display_name": "1 Main St, Chennai, Tamil Nadu, India",
                    "lat": "13.0827",
                    "lon": "80.2707",
                    "address": {"city": "Chennai", "postcode": "600001", "state": "Tamil Nadu"},
                }
            ],
        )
    )
    results = await search_addresses("1 Main St", "TestAgent/1.0")
    assert len(results) == 1
    assert results[0]["display_name"] == "1 Main St, Chennai, Tamil Nadu, India"
    assert results[0]["city"] == "Chennai"
    assert results[0]["postal_code"] == "600001"
    assert results[0]["state"] == "Tamil Nadu"
    assert results[0]["latitude"] == 13.0827
    assert results[0]["longitude"] == 80.2707


@respx.mock
async def test_search_addresses_falls_back_to_town_or_village_for_city():
    respx.get(NOMINATIM_SEARCH_URL).mock(
        return_value=httpx.Response(
            200,
            json=[
                {
                    "display_name": "Small Village Rd",
                    "lat": "1.0",
                    "lon": "2.0",
                    "address": {"village": "Tinytown"},
                }
            ],
        )
    )
    results = await search_addresses("Small Village Rd", "TestAgent/1.0")
    assert results[0]["city"] == "Tinytown"


@respx.mock
async def test_search_addresses_returns_empty_list_on_no_results():
    """AC8: no dead end -- caller falls back to manual entry."""
    respx.get(NOMINATIM_SEARCH_URL).mock(return_value=httpx.Response(200, json=[]))
    results = await search_addresses("zzzzznonexistentplace", "TestAgent/1.0")
    assert results == []


@respx.mock
async def test_search_addresses_returns_empty_list_on_provider_error():
    """AC8: provider failure (5xx/network) degrades to [] rather than raising."""
    respx.get(NOMINATIM_SEARCH_URL).mock(return_value=httpx.Response(502))
    results = await search_addresses("1 Main St", "TestAgent/1.0")
    assert results == []


async def test_search_addresses_returns_empty_list_for_blank_query():
    results = await search_addresses("   ", "TestAgent/1.0")
    assert results == []


@respx.mock
async def test_autocomplete_router_returns_address_suggestion_models():
    respx.get(NOMINATIM_SEARCH_URL).mock(
        return_value=httpx.Response(
            200,
            json=[
                {
                    "display_name": "1 Main St, Chennai",
                    "lat": "13.0",
                    "lon": "80.0",
                    "address": {"city": "Chennai", "postcode": "600001"},
                }
            ],
        )
    )
    suggestions = await autocomplete_address(q="1 Main St")
    assert len(suggestions) == 1
    assert suggestions[0].display_name == "1 Main St, Chennai"
    assert suggestions[0].city == "Chennai"
    assert suggestions[0].postal_code == "600001"


@respx.mock
async def test_autocomplete_router_returns_empty_list_not_error_on_no_results():
    respx.get(NOMINATIM_SEARCH_URL).mock(return_value=httpx.Response(200, json=[]))
    suggestions = await autocomplete_address(q="zzzzznonexistentplace")
    assert suggestions == []
