import { HTMLAttributes } from "react";
import clsx from "clsx";

export type CardProps = HTMLAttributes<HTMLDivElement>;

/** Card — bordered white surface. Mirrors the Figma Card pattern reused across BusinessCard/StatCard/ReviewCard and the Profile/Settings templates. */
export function Card({ className, ...props }: CardProps) {
  return <div className={clsx("rounded-xl border border-gray-200 bg-white p-4 shadow-sm", className)} {...props} />;
}
