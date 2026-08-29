import { HTMLAttributes } from "react";
import clsx from "clsx";

type Size = "sm" | "md" | "lg";

const sizeClasses: Record<Size, string> = {
  sm: "text-xl",
  md: "text-2xl",
  lg: "text-3xl",
};

export type PageHeadingProps = HTMLAttributes<HTMLHeadingElement> & {
  /** `sm` for a card title, `md` (default) for a page title, `lg` for a hero-ish page title. */
  size?: Size;
};

/**
 * PageHeading — the `<h1>` for an interior page or a card. Renders the display face
 * (Outfit) at semibold with the `ink` token, matching the home / marketing surfaces so
 * app pages stop falling back to plain system-bold. Always level 1; pass `size` for the
 * type scale and `className` for layout (e.g. `mt-1`).
 */
export function PageHeading({ size = "md", className, children, ...props }: PageHeadingProps) {
  return (
    <h1
      className={clsx("font-display font-semibold tracking-tight text-ink", sizeClasses[size], className)}
      {...props}
    >
      {children}
    </h1>
  );
}
