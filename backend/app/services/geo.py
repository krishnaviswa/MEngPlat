"""Shared geospatial helpers for search and maps."""

import math


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in kilometres between two WGS-84 points."""
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def bounding_box(lat: float, lng: float, radius_km: float) -> tuple[float, float, float, float]:
    """Approximate lat/lng bounds for a circle (min_lat, max_lat, min_lng, max_lng)."""
    delta_lat = radius_km / 111.0
    cos_lat = max(math.cos(math.radians(lat)), 0.01)
    delta_lng = radius_km / (111.0 * cos_lat)
    return lat - delta_lat, lat + delta_lat, lng - delta_lng, lng + delta_lng
