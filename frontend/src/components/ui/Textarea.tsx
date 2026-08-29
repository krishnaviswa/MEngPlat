import { TextareaHTMLAttributes } from "react";
import clsx from "clsx";

type Size = "sm" | "md";

const base =
  "w-full rounded border border-border bg-surface-raised text-ink placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-brand-500 focus:border-brand-500 disabled:opacity-50 disabled:cursor-not-allowed";

const sizeClasses: Record<Size, string> = {
  sm: "px-3 py-2 text-sm",
  md: "px-4 py-2 text-base",
};

// Omit native HTML `size` so our visual size variant isn't intersected to `never`
// (kept parallel with ui/Input and ui/Select even though <textarea> has no `size`).
export type TextareaProps = Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "size"> & {
  size?: Size;
};

/** Textarea — multi-line text field. Mirrors the `ui/Input` primitive; use for review bodies, replies, notes. */
export function Textarea({ size = "sm", className, ...props }: TextareaProps) {
  return <textarea className={clsx(base, sizeClasses[size], className)} {...props} />;
}
