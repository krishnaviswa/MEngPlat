import figma from "@figma/code-connect";
import { PhotoGallery } from "./PhotoGallery";

// Figma: PhotoGallery (Components / Media). The Lightbox frame on the same page
// documents the modal state, which this component renders from its own useState.
figma.connect(PhotoGallery, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=16-34", {
  example: () => <PhotoGallery photos={photos} />,
});
