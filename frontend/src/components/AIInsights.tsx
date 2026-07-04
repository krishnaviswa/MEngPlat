interface AIInsightsProps {
  insights: {
    merchant_summary?: string | null;
    frequently_mentioned_positives?: string[];
    frequently_mentioned_complaints?: string[];
    suggested_responses?: string[];
    monthly_trends?: { month: string; positive: number; neutral: number; negative: number }[];
    sentiment_breakdown?: Record<string, number>;
  };
}

/** AIInsights — merchant panel showing AI suggestions with disclaimer. */
export function AIInsights({ insights }: AIInsightsProps) {
  return (
    <div className="space-y-4 rounded-xl border border-brand-100 bg-brand-50/50 p-6">
      <div>
        <h3 className="text-lg font-semibold text-brand-900">AI Insights</h3>
        <p className="text-xs text-brand-700">
          Suggestions only — not definitive judgments. Verify in person before acting.
        </p>
      </div>
      {insights.merchant_summary && (
        <section>
          <h4 className="font-medium text-gray-800">Overall Summary</h4>
          <p className="mt-1 text-sm text-gray-700">{insights.merchant_summary}</p>
        </section>
      )}
      <div className="grid gap-4 md:grid-cols-2">
        <section>
          <h4 className="font-medium text-green-800">Frequently Mentioned Positives</h4>
          <ul className="mt-1 list-inside list-disc text-sm text-gray-700">
            {(insights.frequently_mentioned_positives || []).map((p) => (
              <li key={p}>{p}</li>
            ))}
          </ul>
        </section>
        <section>
          <h4 className="font-medium text-red-800">Frequently Mentioned Complaints</h4>
          <ul className="mt-1 list-inside list-disc text-sm text-gray-700">
            {(insights.frequently_mentioned_complaints || []).map((c) => (
              <li key={c}>{c}</li>
            ))}
          </ul>
        </section>
      </div>
      {(insights.suggested_responses || []).length > 0 && (
        <section>
          <h4 className="font-medium text-gray-800">Suggested Owner Responses</h4>
          {insights.suggested_responses!.map((r, i) => (
            <blockquote key={i} className="mt-2 rounded border-l-4 border-brand-400 bg-white p-3 text-sm italic">
              {r}
            </blockquote>
          ))}
        </section>
      )}
    </div>
  );
}
