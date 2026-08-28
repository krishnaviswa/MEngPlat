import { HTMLAttributes } from "react";
import clsx from "clsx";

export type CardProps = HTMLAttributes<HTMLDivElement>;

/** Shared surface classes for Card and anything that needs to look like one (e.g. an interactive StatCard). */
export const cardSurface = "rounded-xl border border-border bg-surface-raised p-4 shadow-sm";

/** Card — bordered white surface. Mirrors the Figma Card pattern reused across BusinessCard/StatCard/ReviewCard and the Profile/Settings templates. */
export function Card({ className, ...props }: CardProps) {
  return <div className={clsx(cardSurface, className)} {...props} />;
}
