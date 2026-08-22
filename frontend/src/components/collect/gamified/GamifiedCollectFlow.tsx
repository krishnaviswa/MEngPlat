"use client";

import { useState } from "react";
import { StepCard } from "./StepCard";
import { StarStep } from "./StarStep";
import { ChipStep } from "./ChipStep";
import { TextStep } from "./TextStep";

type GamifiedScreen = "stars" | "chips" | "text";

export interface GamifiedCollectFlowProps {
  rating: number;
  setRating: (rating: number) => void;
  selectedChips: string[];
  toggleChip: (chip: string) => void;
  body: string;
  setBody: (body: string) => void;
  fillDraft: () => void;
  error: string;
  onSubmit: () => void | Promise<void>;
}

/**
 * Tap-through, one-question-at-a-time presentation of the same stars → chips → text steps (S-119).
 * All rating/chip/body/submit state and logic stays owned by the parent page — this component is
 * presentation/interaction only, so it can be toggled off without touching the data layer.
 */
export function GamifiedCollectFlow({
  rating,
  setRating,
  selectedChips,
  toggleChip,
  body,
  setBody,
  fillDraft,
  error,
  onSubmit,
}: GamifiedCollectFlowProps) {
  const [screen, setScreen] = useState<GamifiedScreen>("stars");

  return (
    <div className="mt-6">
      <StepCard screenKey={screen}>
        {screen === "stars" && (
          <StarStep
            rating={rating}
            onSelect={(value) => {
              setRating(value);
              setScreen("chips");
            }}
          />
        )}
        {screen === "chips" && (
          <ChipStep
            selectedChips={selectedChips}
            onToggle={toggleChip}
            onContinue={() => setScreen("text")}
            onBack={() => setScreen("stars")}
          />
        )}
        {screen === "text" && (
          <TextStep
            body={body}
            setBody={setBody}
            fillDraft={fillDraft}
            error={error}
            onBack={() => setScreen("chips")}
            onSubmit={onSubmit}
          />
        )}
      </StepCard>
    </div>
  );
}
