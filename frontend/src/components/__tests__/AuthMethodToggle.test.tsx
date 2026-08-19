import { fireEvent, render, screen } from "@testing-library/react";
import { AuthMethodToggle } from "@/components/AuthMethodToggle";

describe("AuthMethodToggle", () => {
  it("selects Authenticator by default styling and switches to Mobile OTP", () => {
    const onChange = jest.fn();
    render(<AuthMethodToggle value="authenticator" onChange={onChange} />);
    expect(screen.getByRole("radio", { name: /authenticator/i })).toHaveAttribute("aria-checked", "true");
    fireEvent.click(screen.getByRole("radio", { name: /mobile otp/i }));
    expect(onChange).toHaveBeenCalledWith("otp");
  });
});
