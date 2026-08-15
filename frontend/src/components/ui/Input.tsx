import { InputHTMLAttributes } from "react";
import clsx from "clsx";

type Size = "sm" | "md";

const base =
  "w-full rounded border border-border bg-surface-raised text-ink placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-brand-500 focus:border-brand-500 disabled:opacity-50 disabled:cursor-not-allowed";

const sizeClasses: Record<Size, string> = {
  sm: "px-3 py-2 text-sm",
  md: "px-4 py-2 text-base",
};

// Omit native HTML `size` (number) so our visual size variant isn't intersected to `never`.
export type InputProps = Omit<InputHTMLAttributes<HTMLInputElement>, "size"> & {
  size?: Size;
};

/** Input — text field. Mirrors the Figma `Input` primitive (Components / Primitives). */
export function Input({ size = "sm", className, ...props }: InputProps) {
  return <input className={clsx(base, sizeClasses[size], className)} {...props} />;
}
