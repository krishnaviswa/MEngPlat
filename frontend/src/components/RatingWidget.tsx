"use client";

import { useState } from "react";

interface RatingWidgetProps {
  value: number;
  onChange?: (rating: number) => void;
  readonly?: boolean;
  size?: "sm" | "md" | "lg";
}

/**
 * RatingWidget — interactive or read-only star rating.
 * Props: value, onChange, readonly, size.
 * State: hoverValue (useState) for hover preview when interactive.
 */
export function RatingWidget({ value, onChange, readonly = false, size = "md" }: RatingWidgetProps) {
  const [hover, setHover] = useState(0);
  const sizeClass = size === "sm" ? "text-sm" : size === "lg" ? "text-2xl" : "text-lg";

  return (
    <div className={`flex gap-0.5 ${sizeClass}`} role="group" aria-label="Rating">
      {[1, 2, 3, 4, 5].map((star) => (
        <button
          key={star}
          type="button"
          disabled={readonly}
          className={`${readonly ? "cursor-default" : "cursor-pointer"} ${
            (hover || value) >= star ? "text-yellow-400" : "text-gray-300"
          }`}
          onMouseEnter={() => !readonly && setHover(star)}
          onMouseLeave={() => !readonly && setHover(0)}
          onClick={() => onChange?.(star)}
          aria-label={`${star} stars`}
        >
          ★
        </button>
      ))}
    </div>
  );
}
