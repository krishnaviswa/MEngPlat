export interface DraftOptions {
  rating: number;
  chips: string[];
  businessName: string;
  category?: string;
  city?: string;
}

const OPENERS: Record<number, string[]> = {
  5: ["Had a wonderful time at", "Absolutely loved my visit to", "Couldn't be happier with"],
  4: ["Had a solid experience at", "Really enjoyed my time at", "Good visit to"],
  3: ["Had a decent experience at", "Mixed feelings about my visit to", "It was an okay trip to"],
  2: ["Was let down by", "Had a below-average visit to", "Not quite what I expected from"],
  1: ["Was disappointed with", "Had a rough experience at", "Struggled with my visit to"],
};

const CHIP_PHRASES: Record<string, Record<"positive" | "negative", string>> = {
  Service: {
    positive: "the staff were attentive and friendly",
    negative: "the service felt slow and inattentive",
  },
  Quality: {
    positive: "everything felt well-made and thoughtfully done",
    negative: "the quality didn't quite meet expectations",
  },
  Value: {
    positive: "it was great value for the price",
    negative: "it felt overpriced for what you get",
  },
  Atmosphere: {
    positive: "the atmosphere was warm and inviting",
    negative: "the atmosphere felt a bit off",
  },
  Cleanliness: {
    positive: "the place was spotless",
    negative: "cleanliness could use some work",
  },
  Speed: {
    positive: "everything moved quickly, no waiting around",
    negative: "things took longer than expected",
  },
};

const CLOSERS: Record<number, string[]> = {
  5: ["Definitely coming back — highly recommend."],
  4: ["Would recommend to others in the area."],
  3: ["Worth a visit, though there's room to improve."],
  2: ["Might give it another chance, but wasn't fully convinced."],
  1: ["Wouldn't recommend based on this visit."],
};

function pick<T>(arr: T[], seed: number): T {
  return arr[seed % arr.length];
}

/** Generates a natural-language starter review from a star rating and selected highlight chips. Pure client-side, no API call. */
export function generateDraft({ rating, chips, businessName, category, city }: DraftOptions): string {
  const clamped = Math.min(5, Math.max(1, Math.round(rating))) as 1 | 2 | 3 | 4 | 5;
  const tone: "positive" | "negative" = clamped >= 4 ? "positive" : clamped <= 2 ? "negative" : "positive";
  const seed = businessName.length + clamped;

  const opener = pick(OPENERS[clamped], seed);
  const place = category ? `${businessName}, a ${category.toLowerCase()}${city ? ` in ${city}` : ""}` : businessName;

  const chipPhrases = chips
    .map((chip) => CHIP_PHRASES[chip]?.[tone])
    .filter(Boolean);

  const middle =
    chipPhrases.length > 0
      ? chipPhrases.length === 1
        ? chipPhrases[0]
        : `${chipPhrases.slice(0, -1).join(", ")} and ${chipPhrases[chipPhrases.length - 1]}`
      : null;

  const closer = pick(CLOSERS[clamped], seed);

  const sentences = [`${opener} ${place}.`];
  if (middle) sentences.push(`${middle.charAt(0).toUpperCase()}${middle.slice(1)}.`);
  sentences.push(closer);

  return sentences.join(" ");
}
