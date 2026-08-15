"use client";

import { useState } from "react";

interface PhotoGalleryProps {
  photos: string[];
  altPrefix?: string;
  /** Override the default 2/4-col grid — e.g. a compact inline row on ReviewCard. */
  gridClassName?: string;
  /** Override the default h-32 thumbnail size. */
  thumbClassName?: string;
}

/**
 * PhotoGallery — responsive grid with lightbox.
 * Props: photos (URLs), altPrefix, optional gridClassName/thumbClassName layout overrides.
 * State: selectedIndex (useState) for modal lightbox.
 */
export function PhotoGallery({
  photos,
  altPrefix = "Photo",
  gridClassName = "grid grid-cols-2 gap-2 md:grid-cols-4",
  thumbClassName = "h-32 w-full",
}: PhotoGalleryProps) {
  const [selected, setSelected] = useState<number | null>(null);

  if (!photos.length) return null;

  return (
    <>
      <div className={gridClassName}>
        {photos.map((url, i) => (
          <button key={url} type="button" onClick={() => setSelected(i)} className="overflow-hidden rounded-lg">
            <img src={url} alt={`${altPrefix} ${i + 1}`} className={`${thumbClassName} object-cover transition hover:scale-105`} />
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
