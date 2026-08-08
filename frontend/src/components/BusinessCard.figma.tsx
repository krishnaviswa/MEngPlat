import figma from "@figma/code-connect";
import { BusinessCard } from "./BusinessCard";

// Figma: BusinessCard (Components / Cards)
// The card is data-driven — Name / Meta / ReviewCount in Figma come from the
// `business` object in code, so they are documentation rather than a prop mapping.
figma.connect(BusinessCard, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=10-9", {
  example: () => <BusinessCard business={business} />,
});
