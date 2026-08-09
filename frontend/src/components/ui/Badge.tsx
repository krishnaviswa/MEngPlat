import { HTMLAttributes } from "react";
import clsx from "clsx";

type Tone = "positive" | "negative" | "neutral";

const toneClasses: Record<Tone, string> = {
  positive: "bg-green-100 text-green-800",
  negative: "bg-red-100 text-red-800",
  neutral: "bg-gray-100 text-gray-900",
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
