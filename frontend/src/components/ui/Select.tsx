import { SelectHTMLAttributes } from "react";
import clsx from "clsx";

type Size = "sm" | "md";

const base =
  "w-full rounded border border-gray-200 bg-white text-gray-900 focus:outline-none focus:ring-1 focus:ring-brand-500 focus:border-brand-500 disabled:opacity-50 disabled:cursor-not-allowed";

const sizeClasses: Record<Size, string> = {
  sm: "px-3 py-2 text-sm",
  md: "px-4 py-2 text-base",
};

export type SelectProps = SelectHTMLAttributes<HTMLSelectElement> & {
  size?: Size;
};

/** Select — native dropdown matching Input styling. Mirrors the Figma Select primitive. */
export function Select({ size = "sm", className, children, ...props }: SelectProps) {
  return (
    <select className={clsx(base, sizeClasses[size], className)} {...props}>
      {children}
    </select>
  );
}
