import type { Business } from "@/lib/api";

export interface MapMarker {
  id: string;
  name: string;
  slug?: string;
  latitude: number;
  longitude: number;
}

function toMarkers(businesses: Business[]): MapMarker[] {
  return businesses
    .filter((b) => b.latitude != null && b.longitude != null)
    .map((b) => ({
      id: b.id,
      name: b.name,
      slug: b.slug,
      latitude: b.latitude!,
      longitude: b.longitude!,
    }));
}

/** Convenience helper for server pages that already have Business[]. Kept out of BusinessMap.tsx
 * (a "use client" module that imports leaflet) so Server Components can call it without pulling
 * browser-only Leaflet init code into the server bundle. */
export function businessMarkers(businesses: Business[]): MapMarker[] {
  return toMarkers(businesses);
}
