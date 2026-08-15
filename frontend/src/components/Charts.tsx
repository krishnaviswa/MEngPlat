"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

interface ChartsProps {
  data: { name: string; value: number }[];
  emptyMessage?: string;
  variant?: "bar" | "area" | "line";
}

/** CHART_COLORS — light/dark Recharts palette. Recharts SVG props read JS values directly, so
 *  Tailwind `dark:` classes can't reach them; resolved per-render from `useTheme().resolvedTheme`
 *  instead (S-045, placeholder values pending Figma confirmation — see slice doc). */
const CHART_COLORS = {
  light: { stroke: "#0284c7", fill: "#7dd3fc", solid: "#0284c7", grid: "#e2e8f0", axisText: "#475569" },
  dark: { stroke: "#38bdf8", fill: "#0c4a6e", solid: "#38bdf8", grid: "#2e2e2e", axisText: "#94a3b8" },
} as const;

/** Charts — Recharts bar/area/line for dashboard series. Theme-aware (S-045): palette, gridlines,
 *  legend, and tooltip repaint via `resolvedTheme`. */
export function Charts({ data, emptyMessage, variant = "bar" }: ChartsProps) {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Default to light pre-mount; acceptable since Charts only renders on dashboard routes
  // reached after navigation/auth, not the cold first paint AC 1 cares about.
  const theme = mounted && resolvedTheme === "dark" ? "dark" : "light";
  const colors = CHART_COLORS[theme];

  if (!data.length) {
    return <p className="text-sm text-muted">{emptyMessage ?? "No chart data yet."}</p>;
  }

  const tooltipContentStyle = {
    backgroundColor: theme === "dark" ? "#1e1e1e" : "#ffffff",
    border: `1px solid ${colors.grid}`,
    color: theme === "dark" ? "#e2e8f0" : "#0f172a",
  };

  const inner =
    variant === "area" ? (
      <AreaChart data={data}>
        <CartesianGrid stroke={colors.grid} />
        <XAxis dataKey="name" stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <YAxis allowDecimals={false} stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <Tooltip contentStyle={tooltipContentStyle} />
        <Legend />
        <Area type="monotone" dataKey="value" stroke={colors.stroke} fill={colors.fill} />
      </AreaChart>
    ) : variant === "line" ? (
      <LineChart data={data}>
        <CartesianGrid stroke={colors.grid} />
        <XAxis dataKey="name" stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <YAxis allowDecimals={false} stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <Tooltip contentStyle={tooltipContentStyle} />
        <Legend />
        <Line type="monotone" dataKey="value" stroke={colors.stroke} />
      </LineChart>
    ) : (
      <BarChart data={data}>
        <CartesianGrid stroke={colors.grid} />
        <XAxis dataKey="name" stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <YAxis allowDecimals={false} stroke={colors.axisText} tick={{ fill: colors.axisText }} />
        <Tooltip contentStyle={tooltipContentStyle} />
        <Legend />
        <Bar dataKey="value" fill={colors.solid} radius={[4, 4, 0, 0]} />
      </BarChart>
    );

  return (
    <div className="h-64 w-full" data-chart-variant={variant}>
      <ResponsiveContainer width="100%" height="100%">
        {inner}
      </ResponsiveContainer>
    </div>
  );
}
