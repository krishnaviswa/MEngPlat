"use client";

import { Area, AreaChart, Bar, BarChart, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

interface ChartsProps {
  data: { name: string; value: number }[];
  emptyMessage?: string;
  variant?: "bar" | "area" | "line";
}

/** Charts — Recharts bar/area/line for dashboard series. */
export function Charts({ data, emptyMessage, variant = "bar" }: ChartsProps) {
  if (!data.length) {
    return <p className="text-sm text-gray-500">{emptyMessage ?? "No chart data yet."}</p>;
  }

  const inner =
    variant === "area" ? (
      <AreaChart data={data}>
        <XAxis dataKey="name" />
        <YAxis allowDecimals={false} />
        <Tooltip />
        <Area type="monotone" dataKey="value" stroke="#0284c7" fill="#7dd3fc" />
      </AreaChart>
    ) : variant === "line" ? (
      <LineChart data={data}>
        <XAxis dataKey="name" />
        <YAxis allowDecimals={false} />
        <Tooltip />
        <Line type="monotone" dataKey="value" stroke="#0284c7" />
      </LineChart>
    ) : (
      <BarChart data={data}>
        <XAxis dataKey="name" />
        <YAxis allowDecimals={false} />
        <Tooltip />
        <Bar dataKey="value" fill="#0284c7" radius={[4, 4, 0, 0]} />
      </BarChart>
    );

  return (
    <div className="h-64 w-full">
      <ResponsiveContainer width="100%" height="100%">
        {inner}
      </ResponsiveContainer>
    </div>
  );
}
