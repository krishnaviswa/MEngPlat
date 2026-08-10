interface BusinessHoursProps {
  hours?: Record<string, unknown> | null;
}

/**
 * BusinessHours — renders a business's opening hours as a label/value list.
 * Props: hours — the `business_hours` JSONB field. Skips empty values; shows
 * "Hours not listed" when nothing usable remains.
 */
export function BusinessHours({ hours }: BusinessHoursProps) {
  const entries =
    hours && typeof hours === "object"
      ? Object.entries(hours).filter(([, value]) => value != null && value !== "")
      : [];

  if (entries.length === 0) {
    return <p className="text-sm text-gray-500">Hours not listed</p>;
  }

  return (
    <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
      {entries.map(([day, value]) => (
        <div key={day} className="contents">
          <dt className="font-medium capitalize text-gray-700">{day}</dt>
          <dd className="text-gray-600">{typeof value === "string" ? value : JSON.stringify(value)}</dd>
        </div>
      ))}
    </dl>
  );
}
