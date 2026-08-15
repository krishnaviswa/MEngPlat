/** Category/city median ratings — directory math, not an AI verdict. */
export function BenchmarkCard({
  own,
  categoryMedian,
  cityMedian,
  disclaimer,
}: {
  own: number;
  categoryMedian: number | null;
  cityMedian: number | null;
  disclaimer: string;
}) {
  return (
    <section className="rounded-xl border bg-surface-raised p-4">
      <h3 className="font-semibold">Local rating snapshot</h3>
      <p className="mt-1 text-xs text-muted">{disclaimer}</p>
      <dl className="mt-3 grid gap-2 text-sm sm:grid-cols-3">
        <div>
          <dt className="text-muted">Your average</dt>
          <dd className="text-lg font-semibold">{own.toFixed(1)}</dd>
        </div>
        <div>
          <dt className="text-muted">Category median</dt>
          <dd className="text-lg font-semibold">
            {categoryMedian == null ? "Not enough nearby listings yet." : categoryMedian.toFixed(1)}
          </dd>
        </div>
        <div>
          <dt className="text-muted">City median</dt>
          <dd className="text-lg font-semibold">
            {cityMedian == null ? "Not enough nearby listings yet." : cityMedian.toFixed(1)}
          </dd>
        </div>
      </dl>
    </section>
  );
}
