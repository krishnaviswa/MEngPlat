import figma from "@figma/code-connect";
import { Navbar } from "./Navbar";

// Figma: Navbar (Components / Navigation)
figma.connect(Navbar, "https://www.figma.com/design/X0XXhJiwW8SxFdMf39n2t3?node-id=12-44", {
  props: {
    role: figma.enum("Role", {
      "Logged out": undefined,
      Customer: { id: "1", email: "", full_name: "Priya Raghavan", role: "customer" },
      Merchant: { id: "1", email: "", full_name: "Priya Raghavan", role: "merchant" },
      Admin: { id: "1", email: "", full_name: "Priya Raghavan", role: "admin" },
    }),
  },
  example: (props) => <Navbar user={props.role} onLogout={() => {}} />,
});
