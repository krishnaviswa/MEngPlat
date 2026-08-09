"use client";

/** UseLocationButton — reloads /search with browser geolocation lat/lng query params. */
export function UseLocationButton() {
  const handleClick = () => {
    if (!navigator.geolocation) {
      window.alert("Geolocation is not supported in this browser.");
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const params = new URLSearchParams(window.location.search);
        params.set("lat", String(pos.coords.latitude));
        params.set("lng", String(pos.coords.longitude));
        if (!params.has("radius_km")) {
          params.set("radius_km", "10");
        }
        window.location.href = `/search?${params.toString()}`;
      },
      () => {
        window.alert("Could not get your location. Check browser permissions.");
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 },
    );
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      className="rounded border border-brand-200 bg-brand-50 px-3 py-1.5 text-sm font-medium text-brand-800 hover:bg-brand-100"
    >
      Use my location
    </button>
  );
}
