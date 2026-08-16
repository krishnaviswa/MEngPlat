/** Scattered speech bubbles at odd angles — feedback living in disconnected places. */
function ScatteredIcon() {
  return (
    <svg viewBox="0 0 40 40" fill="none" className="h-6 w-6" aria-hidden="true">
      <path
        d="M6 10a3 3 0 0 1 3-3h7a3 3 0 0 1 3 3v5a3 3 0 0 1-3 3h-1.5L12 21v-3H9a3 3 0 0 1-3-3v-5Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
        opacity="0.45"
        transform="rotate(-8 12 13)"
      />
      <path
        d="M21 20a3 3 0 0 1 3-3h7a3 3 0 0 1 3 3v5a3 3 0 0 1-3 3h-1l-2.5 3v-3H24a3 3 0 0 1-3-3v-5Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
        transform="rotate(6 29 25)"
      />
      <circle cx="10" cy="30" r="2.6" stroke="currentColor" strokeWidth="1.6" opacity="0.7" />
    </svg>
  );
}

/** A flat bar chart resolving into one clearly taller bar under a magnifying glass — signal found in the noise. */
function InsightIcon() {
  return (
    <svg viewBox="0 0 40 40" fill="none" className="h-6 w-6" aria-hidden="true">
      <path d="M8 29V17M15.5 29V21M23 29V13" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" opacity="0.5" />
      <circle cx="24" cy="16" r="8" stroke="currentColor" strokeWidth="1.6" />
      <path d="M29.8 21.8 34 26" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      <path d="M21 16h6M24 13v6" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

/** A fuzzy "…" bubble giving way to a checklist bubble — vague feedback turning specific. */
function ClarityIcon() {
  return (
    <svg viewBox="0 0 40 40" fill="none" className="h-6 w-6" aria-hidden="true">
      <path
        d="M5 12a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3h-1l-2.5 3v-3H8a3 3 0 0 1-3-3v-4Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
        opacity="0.45"
      />
      <circle cx="9.5" cy="14" r="0.9" fill="currentColor" opacity="0.45" />
      <circle cx="13" cy="14" r="0.9" fill="currentColor" opacity="0.45" />
      <circle cx="16.5" cy="14" r="0.9" fill="currentColor" opacity="0.45" />
      <path
        d="M18 22a3 3 0 0 1 3-3h9a3 3 0 0 1 3 3v6a3 3 0 0 1-3 3H23l-2.5 3v-3H21a3 3 0 0 1-3-3v-6Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
      <path d="M22.5 25.5 24 27l3.5-3.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

const POINTS = [
  {
    n: "01",
    title: "Your reviews are scattered",
    body: "Google reviews, word of mouth, in-person feedback — there's no single place to see it all.",
    Icon: ScatteredIcon,
  },
  {
    n: "02",
    title: "You don't know what's actually working",
    body: "A star average alone doesn't say which service, staff member, or product is driving satisfaction.",
    Icon: InsightIcon,
  },
  {
    n: "03",
    title: "Vague reviews don't help anyone",
    body: "\"Good place\" tells future customers and the owner nothing actionable — MerchantHub's guided review flow fixes that at the source.",
    Icon: ClarityIcon,
  },
];

/** ProblemSection — three honestly-scoped problem points, each paired with a hand-drawn icon evoking the customer's own mental picture of the gap. No props. */
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
        <ol className="mt-12 grid gap-6 md:grid-cols-3">
          {POINTS.map(({ n, title, body, Icon }) => (
            <li
              key={n}
              className="group rounded-2xl border border-border bg-surface-raised p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
            >
              <div className="flex items-center justify-between">
                <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brand-100 text-brand-700 dark:bg-brand-900/40 dark:text-brand-300">
                  <Icon />
                </span>
                <p className="font-display text-sm font-semibold tracking-widest text-brand-700 dark:text-brand-300">{n}</p>
              </div>
              <h3 className="mt-4 font-display text-xl font-semibold text-ink">{title}</h3>
              <p className="mt-2 text-muted">{body}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
