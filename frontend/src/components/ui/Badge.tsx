import { HTMLAttributes } from "react";
import clsx from "clsx";

// S-083: "info"/"brand" are judgment-neutral classification tones (e.g. user role) --
// distinct from positive/negative's good/bad meaning used for sentiment/status elsewhere.
export type Tone = "positive" | "negative" | "neutral" | "info" | "brand";

const toneClasses: Record<Tone, string> = {
  positive: "bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300",
  negative: "bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300",
  neutral: "bg-gray-100 text-gray-900 dark:bg-gray-800 dark:text-gray-200",
  info: "bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300",
  brand: "bg-brand-100 text-brand-800 dark:bg-brand-900/40 dark:text-brand-300",
};

export type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: Tone;
};

/** Badge — small pill tag. Mirrors the Figma `Badge` primitive; tone maps to AI sentiment (positive/negative/neutral) on ReviewCard. */
export function Badge({ tone = "neutral", className, ...props }: BadgeProps) {
  return (
    <span
      className={clsx("inline-flex items-center rounded-full px-2 py-0.5 text-xs", toneClasses[tone], className)}
      {...props}
    />
  );
}
