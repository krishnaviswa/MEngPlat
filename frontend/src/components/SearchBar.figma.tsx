import figma from "@figma/code-connect";
import { SearchBar } from "./SearchBar";

// Figma: SearchBar (Components / Search)
figma.connect(SearchBar, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=15-2", {
  example: () => <SearchBar placeholder="Search restaurants, salons, shops..." />,
});
