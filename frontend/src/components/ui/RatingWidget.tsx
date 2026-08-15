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

  // Half-star display is readonly-only (S-046 AC6/7) — the interactive picker below
  // never computes or renders this, so it can't affect whole-star submission behavior.
  const displayValue = readonly ? Math.round(value * 2) / 2 : value;

  return (
    <div className={clsx("flex gap-0.5", sizeClasses[size])} role="group" aria-label="Rating">
      {[1, 2, 3, 4, 5].map((star) => {
        if (readonly) {
          const isHalf = displayValue >= star - 0.5 && displayValue < star;
          return (
            <button key={star} type="button" disabled className="cursor-default" aria-label={`${star} stars`}>
              {isHalf ? (
                <span className="relative inline-block" aria-hidden>
                  <span className="text-gray-300 dark:text-gray-600">★</span>
                  <span className="absolute inset-0 w-1/2 overflow-hidden text-yellow-400 dark:text-yellow-500">★</span>
                </span>
              ) : (
                <span className={displayValue >= star ? "text-yellow-400 dark:text-yellow-500" : "text-gray-300 dark:text-gray-600"}>
                  ★
                </span>
              )}
            </button>
          );
        }

        return (
          <button
            key={star}
            type="button"
            className={clsx(
              "cursor-pointer",
              (hover || value) >= star ? "text-yellow-400 dark:text-yellow-500" : "text-gray-300 dark:text-gray-600",
            )}
            onMouseEnter={() => setHover(star)}
            onMouseLeave={() => setHover(0)}
            onClick={() => onChange?.(star)}
            aria-label={`${star} stars`}
          >
            ★
          </button>
        );
      })}
    </div>
  );
}
