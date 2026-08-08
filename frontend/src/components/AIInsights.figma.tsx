import figma from "@figma/code-connect";
import { AIInsights } from "./AIInsights";

// Figma: AIInsights (Components / AI & Data)
// The disclaimer line is part of the component, not optional — keep it in any variant.
figma.connect(AIInsights, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=16-2", {
  example: () => <AIInsights insights={insights} />,
});
