"use client";

import type { MapMarker } from "@/lib/mapMarkers";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";

/** Pin icon — Leaflet defaults break under bundlers without explicit asset URLs. */
const markerIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

interface BusinessMapProps {
  /** Businesses or explicit markers to plot (must include coordinates). */
  markers: MapMarker[];
  /** Map centre; defaults to the single marker or the markers' centroid. */
  center?: [number, number];
  zoom?: number;
  className?: string;
  height?: string;
}

/** BusinessMap — Leaflet + OpenStreetMap markers; click navigates when slug is set. */
export function BusinessMap({
  markers,
  center,
  zoom = 13,
  className = "",
  height = "320px",
}: BusinessMapProps) {
  if (markers.length === 0) {
    return null;
  }

  const mapCenter: [number, number] =
    center ??
    (markers.length === 1
      ? [markers[0].latitude, markers[0].longitude]
      : [
          markers.reduce((sum, m) => sum + m.latitude, 0) / markers.length,
          markers.reduce((sum, m) => sum + m.longitude, 0) / markers.length,
        ]);

  return (
    <div className={`overflow-hidden rounded-xl border bg-white shadow-sm ${className}`} style={{ height }}>
      <MapContainer center={mapCenter} zoom={zoom} scrollWheelZoom={false} style={{ height: "100%", width: "100%" }}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {markers.map((m) => (
          <Marker key={m.id} position={[m.latitude, m.longitude]} icon={markerIcon}>
            <Popup>
              {m.slug ? (
                <a href={`/businesses/${m.slug}`} className="font-medium text-brand-700 hover:underline">
                  {m.name}
                </a>
              ) : (
                <span className="font-medium">{m.name}</span>
              )}
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}

/** Default export for next/dynamic lazy loading. */
export default BusinessMap;
