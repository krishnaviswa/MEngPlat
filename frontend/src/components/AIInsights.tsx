interface TopicItem {
  label: string;
  count: number;
  sentiment: "positive" | "negative" | "mixed";
  example_quote: string;
}

interface AIInsightsProps {
  insights: {
    merchant_summary?: string | null;
    frequently_mentioned_positives?: string[];
    frequently_mentioned_complaints?: string[];
    suggested_responses?: string[];
    monthly_trends?: { month: string; positive: number; neutral: number; negative: number }[];
    sentiment_breakdown?: Record<string, number>;
    degraded?: boolean;
    topics?: TopicItem[];
    topics_degraded?: boolean;
    topics_insufficient_data?: boolean;
    topics_unavailable?: boolean;
  };
}

/** AIInsights — merchant panel showing AI suggestions with disclaimer. */
export function AIInsights({ insights }: AIInsightsProps) {
  return (
    <div className="space-y-4 rounded-xl border border-brand-100 bg-brand-50/50 p-6 dark:border-brand-800/50 dark:bg-brand-900/20">
      <div>
        <h3 className="text-lg font-semibold text-brand-900 dark:text-brand-200">AI Insights</h3>
        <p className="text-xs text-brand-700 dark:text-brand-300">
          Suggestions only — not definitive judgments. Verify in person before acting.
        </p>
      </div>
      {insights.merchant_summary && (
        <section>
          <h4 className="font-medium text-ink">Overall Summary</h4>
          <p className="mt-1 text-sm text-muted">{insights.merchant_summary}</p>
        </section>
      )}
      <div className="grid gap-4 md:grid-cols-2">
        <section>
          <h4 className="font-medium text-green-800 dark:text-green-300">Frequently Mentioned Positives</h4>
          <ul className="mt-1 list-inside list-disc text-sm text-muted">
            {(insights.frequently_mentioned_positives || []).map((p) => (
              <li key={p}>{p}</li>
            ))}
          </ul>
        </section>
        <section>
          <h4 className="font-medium text-red-800 dark:text-red-300">Frequently Mentioned Complaints</h4>
          <ul className="mt-1 list-inside list-disc text-sm text-muted">
            {(insights.frequently_mentioned_complaints || []).map((c) => (
              <li key={c}>{c}</li>
            ))}
          </ul>
        </section>
      </div>
      {(insights.suggested_responses || []).length > 0 && (
        <section>
          <h4 className="font-medium text-ink">Suggested Owner Responses</h4>
          {insights.suggested_responses!.map((r, i) => (
            <blockquote key={i} className="mt-2 rounded border-l-4 border-brand-400 bg-surface-raised p-3 text-sm italic">
              {r}
            </blockquote>
          ))}
        </section>
      )}
      {(insights.topics_insufficient_data || insights.topics_unavailable || (insights.topics || []).length > 0) && (
        <section>
          <h4 className="font-medium text-ink">Common Themes</h4>
          {insights.topics_insufficient_data ? (
            <p className="mt-1 text-sm text-muted">Not enough reviews yet to identify common themes.</p>
          ) : insights.topics_unavailable ? (
            <p className="mt-1 text-sm text-muted">Common themes are temporarily unavailable.</p>
          ) : (
            <ul className="mt-2 flex flex-wrap gap-2 text-sm text-muted">
              {insights.topics!.map((t) => (
                <li
                  key={t.label}
                  className="rounded-full border-l-4 border-brand-400 bg-surface-raised px-3 py-1"
                >
                  {insights.topics_degraded ? "Mock/degraded data. " : ""}
                  {t.label} — {t.count} mentions · {t.sentiment} (suggestion)
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
      {(insights.monthly_trends || []).length > 0 && (
        <section>
          <h4 className="font-medium text-ink">AI Trend Suggestion</h4>
          <p className="mt-1 text-xs text-amber-700 dark:text-amber-400">
            {insights.degraded ? "Mock/degraded data. " : ""}
            Not computed from your review history — a suggestion, not a fact. See the Review volume chart above for
            actual review dates.
          </p>
          <ul className="mt-2 space-y-1 text-sm text-muted">
            {insights.monthly_trends!.map((t) => (
              <li key={t.month}>
                {t.month}: {t.positive} positive · {t.neutral} neutral · {t.negative} negative (suggestion)
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
