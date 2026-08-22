"use client";

export function TextStep({
  body,
  setBody,
  fillDraft,
  error,
  onBack,
  onSubmit,
}: {
  body: string;
  setBody: (body: string) => void;
  fillDraft: () => void;
  error: string;
  onBack: () => void;
  onSubmit: () => void | Promise<void>;
}) {
  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        void onSubmit();
      }}
      className="space-y-3 text-left"
    >
      <div className="flex items-center justify-between">
        <p className="animate-bounce-in text-sm font-medium text-muted">Write your review</p>
        <button type="button" onClick={fillDraft} className="text-sm font-medium text-brand-700 hover:underline">
          Generate a starter →
        </button>
      </div>
      <textarea
        required
        minLength={10}
        value={body}
        onChange={(e) => setBody(e.target.value)}
        className="w-full rounded border border-border bg-surface-raised text-ink p-2 text-sm"
        rows={6}
        placeholder="Share what made your visit memorable…"
      />
      <div className="h-1 w-full overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
        <div
          className={`h-full transition-all ${body.length >= 50 ? "bg-green-500" : "bg-brand-400"}`}
          style={{ width: `${Math.min(100, (body.length / 50) * 100)}%` }}
        />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex items-center justify-between gap-2">
        <button type="button" onClick={onBack} className="text-sm text-muted hover:underline">
          ← Back
        </button>
        <button type="submit" className="rounded bg-brand-600 px-4 py-2 text-sm text-white">
          Submit review
        </button>
      </div>
    </form>
  );
}
