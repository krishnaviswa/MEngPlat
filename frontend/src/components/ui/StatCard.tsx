import { ReactNode } from "react";
import clsx from "clsx";
import { Card, cardSurface } from "@/components/ui/Card";

export type StatCardProps = {
  label: string;
  value: ReactNode;
  icon?: ReactNode;
  trend?: ReactNode;
  className?: string;
  /** Render the tile as a link. Mutually exclusive with `onClick`. */
  href?: string;
  /** Render the tile as a button (e.g. scroll-to-section). Ignored if `href` is set. */
  onClick?: () => void;
};

const interactiveSurface = "block transition hover:border-brand-300 hover:shadow-sm";

/**
 * StatCard — labeled metric tile built on Card.
 * Props: label, value, optional icon/trend, optional `href` (renders <a>) or `onClick`
 * (renders <button>) to make the whole tile a single actionable target. Mirrors the
 * Figma StatCard pattern.
 */
export function StatCard({ label, value, icon, trend, className, href, onClick }: StatCardProps) {
  const body = (
    <>
      <div className="flex items-start justify-between gap-2">
        <p className="text-sm text-muted">{label}</p>
        {icon}
      </div>
      <p className="text-2xl font-bold">{value}</p>
      {trend != null && <div className="mt-1 text-sm text-muted">{trend}</div>}
    </>
  );

  if (href) {
    return (
      <a href={href} className={clsx(cardSurface, interactiveSurface, className)}>
        {body}
      </a>
    );
  }

  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={clsx(cardSurface, interactiveSurface, "w-full text-left", className)}>
        {body}
      </button>
    );
  }

  return <Card className={clsx(className)}>{body}</Card>;
}
