/** ProblemSection — three honestly-scoped problem points, "How it works" 01/02/03 treatment. No props. */
export function ProblemSection() {
  return (
    <section className="mh-section-reveal border-b border-border px-4 py-16">
      <div className="mx-auto max-w-6xl">
        <h2 className="text-center font-display text-3xl font-semibold tracking-tight text-ink">
          The problem with local reviews today
        </h2>
        <p className="mx-auto mt-2 max-w-xl text-center text-muted">
          MerchantHub is built around three specific gaps we kept seeing
        </p>
        <ol className="mt-12 grid gap-10 md:grid-cols-3">
          {[
            {
              n: "01",
              title: "Your reviews are scattered",
              body: "Google reviews, word of mouth, in-person feedback — there's no single place to see it all.",
            },
            {
              n: "02",
              title: "You don't know what's actually working",
              body: "A star average alone doesn't say which service, staff member, or product is driving satisfaction.",
            },
            {
              n: "03",
              title: "Vague reviews don't help anyone",
              body: "\"Good place\" tells future customers and the owner nothing actionable — MerchantHub's guided review flow fixes that at the source.",
            },
          ].map((point) => (
            <li key={point.n} className="border-t border-brand-200 pt-6">
              <p className="font-display text-sm font-semibold tracking-widest text-brand-700">{point.n}</p>
              <h3 className="mt-3 font-display text-xl font-semibold text-ink">{point.title}</h3>
              <p className="mt-2 text-muted">{point.body}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
