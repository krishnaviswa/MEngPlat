"use client";

import { CHIPS } from "@/components/collect/constants";

export function ChipStep({
  selectedChips,
  onToggle,
  onContinue,
  onBack,
}: {
  selectedChips: string[];
  onToggle: (chip: string) => void;
  onContinue: () => void;
  onBack: () => void;
}) {
  return (
    <div>
      <p className="animate-bounce-in text-sm font-medium text-muted">What stood out? (optional)</p>
      <div className="mt-3 flex flex-wrap justify-center gap-2">
        {CHIPS.map((chip) => (
          <button
            key={chip}
            type="button"
            onClick={() => onToggle(chip)}
            className={`rounded-full border px-3 py-1 text-sm transition ${
              selectedChips.includes(chip)
                ? "border-brand-600 bg-brand-600 text-white"
                : "border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            }`}
          >
            {chip}
          </button>
        ))}
      </div>
      <div className="mt-6 flex items-center justify-between gap-2">
        <button type="button" onClick={onBack} className="text-sm text-muted hover:underline">
          ← Back
        </button>
        <button type="button" onClick={onContinue} className="rounded bg-brand-600 px-4 py-2 text-sm font-medium text-white">
          Continue →
        </button>
      </div>
    </div>
  );
}
