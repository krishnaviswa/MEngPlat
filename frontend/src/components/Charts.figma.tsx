import figma from "@figma/code-connect";
import { Charts } from "./Charts";

// Figma: Chart (Components / AI & Data)
// Bars use brand-600 (#0284c7) with a 4px top radius — matches the Recharts <Bar> config.
figma.connect(Charts, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=16-22", {
  example: () => <Charts data={sentimentData} />,
});
