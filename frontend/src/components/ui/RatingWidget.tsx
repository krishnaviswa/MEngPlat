"use client";

import { useState } from "react";
import clsx from "clsx";

export interface RatingWidgetProps {
  value: number;
  onChange?: (rating: number) => void;
  readonly?: boolean;
  size?: "sm" | "md" | "lg";
}

const sizeClasses = {
  sm: "text-sm",
  md: "text-lg",
  lg: "text-2xl",
} as const;

/**
 * RatingWidget (ui) — star rating primitive aligned with other ui/ components.
 * Additive copy of components/RatingWidget using clsx; existing call sites unchanged.
 */
export function RatingWidget({ value, onChange, readonly = false, size = "md" }: RatingWidgetProps) {
  const [hover, setHover] = useState(0);

  return (
    <div className={clsx("flex gap-0.5", sizeClasses[size])} role="group" aria-label="Rating">
      {[1, 2, 3, 4, 5].map((star) => (
        <button
          key={star}
          type="button"
          disabled={readonly}
          className={clsx(
            readonly ? "cursor-default" : "cursor-pointer",
            (hover || value) >= star ? "text-yellow-400" : "text-gray-300",
          )}
          onMouseEnter={() => !readonly && setHover(star)}
          onMouseLeave={() => !readonly && setHover(0)}
          onClick={() => {
            if (!readonly) onChange?.(star);
          }}
          aria-label={`${star} stars`}
        >
          ★
        </button>
      ))}
    </div>
  );
}
