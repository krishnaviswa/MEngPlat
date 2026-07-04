"use client";

import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

interface ChartsProps {
  data: { name: string; value: number }[];
}

/** Charts — Recharts bar chart for sentiment/volume breakdown. Props: data array. */
export function Charts({ data }: ChartsProps) {
  if (!data.length) {
    return <p className="text-sm text-gray-500">No chart data yet.</p>;
  }

  return (
    <div className="h-64 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data}>
          <XAxis dataKey="name" />
          <YAxis allowDecimals={false} />
          <Tooltip />
          <Bar dataKey="value" fill="#0284c7" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
