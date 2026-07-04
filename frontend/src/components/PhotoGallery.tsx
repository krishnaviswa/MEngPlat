"use client";

import { useState } from "react";

interface PhotoGalleryProps {
  photos: string[];
  altPrefix?: string;
}

/**
 * PhotoGallery — responsive grid with lightbox.
 * Props: photos (URLs), altPrefix.
 * State: selectedIndex (useState) for modal lightbox.
 */
export function PhotoGallery({ photos, altPrefix = "Photo" }: PhotoGalleryProps) {
  const [selected, setSelected] = useState<number | null>(null);

  if (!photos.length) return null;

  return (
    <>
      <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
        {photos.map((url, i) => (
          <button key={url} type="button" onClick={() => setSelected(i)} className="overflow-hidden rounded-lg">
            <img src={url} alt={`${altPrefix} ${i + 1}`} className="h-32 w-full object-cover transition hover:scale-105" />
          </button>
        ))}
      </div>
      {selected !== null && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
          onClick={() => setSelected(null)}
        >
          <img src={photos[selected]} alt="" className="max-h-full max-w-full rounded-lg" />
        </div>
      )}
    </>
  );
}
