import figma from "@figma/code-connect";
import { RatingWidget } from "./ui/RatingWidget";

// Figma: RatingWidget (Components / Rating)
// The Value variant axis (0-5) maps to the `value` prop; Size maps to sm | md | lg.
figma.connect(RatingWidget, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=9-137", {
  props: {
    value: figma.enum("Value", { "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5 }),
    size: figma.enum("Size", { Small: "sm", Medium: "md", Large: "lg" } as const),
  },
  example: (props) => <RatingWidget value={props.value} size={props.size} readonly />,
});
