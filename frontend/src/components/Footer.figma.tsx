import figma from "@figma/code-connect";
import { Footer } from "./Footer";

// Figma: Footer (Components / Navigation)
figma.connect(Footer, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=14-6", {
  example: () => <Footer />,
});
