import { ReactNode } from "react";
import clsx from "clsx";
import { Card } from "@/components/ui/Card";

export type StatCardProps = {
  label: string;
  value: ReactNode;
  icon?: ReactNode;
  trend?: ReactNode;
  className?: string;
};

/** StatCard — labeled metric tile built on Card. Mirrors the Figma StatCard pattern. */
export function StatCard({ label, value, icon, trend, className }: StatCardProps) {
  return (
    <Card className={clsx(className)}>
      <div className="flex items-start justify-between gap-2">
        <p className="text-sm text-gray-500">{label}</p>
        {icon}
      </div>
      <p className="text-2xl font-bold">{value}</p>
      {trend != null && <div className="mt-1 text-sm text-gray-500">{trend}</div>}
    </Card>
  );
}
