"use client";

import { useState } from "react";
import { BusinessMap } from "./BusinessMapClient";
import type { MapMarker } from "@/lib/mapMarkers";
import { dashboard } from "@/lib/api";
import type { GooglePlaceCandidate } from "@/lib/api";

interface GooglePlacePickerProps {
  businessId: string;
  businessName: string;
  /** Map centre; falls back to the mock provider's own default when null. */
  center: [number, number] | null;
  onLinked: () => void;
}

function toMarker(candidate: GooglePlaceCandidate): MapMarker {
  // No `slug` -- these are Google candidates, not our own businesses, so pins
  // must not navigate anywhere on click (they only select).
  return {
    id: candidate.place_id,
    name: candidate.name,
    latitude: candidate.latitude,
    longitude: candidate.longitude,
  };
}

/**
 * GooglePlacePicker — search box + candidate list + map pins for linking a
 * Google Business Profile (S-048 AC1-5). List-row click and pin click share
 * one `selectedPlaceId` state, so there is exactly one selection path.
 */
export function GooglePlacePicker({ businessId, businessName, center, onLinked }: GooglePlacePickerProps) {
  const [query, setQuery] = useState(businessName);
  const [candidates, setCandidates] = useState<GooglePlaceCandidate[]>([]);
  const [selectedPlaceId, setSelectedPlaceId] = useState<string | null>(null);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [linking, setLinking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (query.trim().length < 2) return;
    setLoading(true);
    setError(null);
    try {
      const { candidates: results } = await dashboard.searchGooglePlaces(businessId, query.trim());
      setCandidates(results);
      setSearched(true);
      setSelectedPlaceId(null);
    } catch (err) {
      // AC5: readable error, existing selection/linked state untouched.
      setError(err instanceof Error ? err.message : "Couldn't reach Google Places right now");
    } finally {
      setLoading(false);
    }
  }

  async function handleConfirm() {
    if (!selectedPlaceId) return;
    const selected = candidates.find((c) => c.place_id === selectedPlaceId);
    setLinking(true);
    setError(null);
    try {
      await dashboard.linkGooglePlace(businessId, selectedPlaceId, selected?.name, selected?.address);
      onLinked();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't link this Google Business Profile");
    } finally {
      setLinking(false);
    }
  }

  const markers = candidates.map(toMarker);

  return (
    <div className="space-y-4">
      <form onSubmit={handleSearch} className="flex gap-2">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search for your business on Google"
          className="flex-1 rounded border border-border bg-surface-raised px-3 py-2 text-sm"
          aria-label="Search Google Places"
        />
        <button
          type="submit"
          disabled={loading || query.trim().length < 2}
          className="rounded bg-brand-600 px-4 py-2 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {loading ? "Searching..." : "Search"}
        </button>
      </form>

      {error && (
        <p role="alert" className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-800/50 dark:bg-red-900/20 dark:text-red-300">
          {error}
        </p>
      )}

      {searched && candidates.length === 0 && !error && (
        <p className="text-sm text-muted">
          No matches found for &quot;{query}&quot;. Try a different search term.
        </p>
      )}

      {candidates.length > 0 && (
        <>
          <BusinessMap
            markers={markers}
            center={center ?? undefined}
            onMarkerClick={(m) => setSelectedPlaceId(m.id)}
            height="240px"
          />
          <ul className="space-y-2">
            {candidates.map((c) => (
              <li key={c.place_id}>
                <button
                  type="button"
                  onClick={() => setSelectedPlaceId(c.place_id)}
                  aria-pressed={selectedPlaceId === c.place_id}
                  className={`w-full rounded border p-3 text-left text-sm transition ${
                    selectedPlaceId === c.place_id
                      ? "border-brand-500 bg-brand-50 dark:bg-brand-900/20"
                      : "border-border bg-surface-raised hover:border-brand-300"
                  }`}
                >
                  <p className="font-medium text-ink">{c.name}</p>
                  <p className="text-muted">{c.address}</p>
                </button>
              </li>
            ))}
          </ul>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={!selectedPlaceId || linking}
            className="rounded bg-brand-600 px-4 py-2 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
          >
            {linking ? "Linking..." : "Link this business"}
          </button>
        </>
      )}
    </div>
  );
}
