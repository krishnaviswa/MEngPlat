import figma from "@figma/code-connect";
import { ReviewCard } from "./ReviewCard";

// Figma: ReviewCard (Components / Cards)
// "Show actions" in Figma is the `showActions` prop. The AI badge tone is derived
// from review.ai_analysis.sentiment rather than set directly.
figma.connect(ReviewCard, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=11-7", {
  props: {
    showActions: figma.boolean("Show actions"),
  },
  example: (props) => <ReviewCard review={review} showActions={props.showActions} />,
});
