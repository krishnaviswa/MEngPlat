import figma from "@figma/code-connect";
import { FilterPanel } from "./FilterPanel";

// Figma: FilterPanel (Components / Search)
figma.connect(FilterPanel, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=15-7", {
  example: () => <FilterPanel />,
});
