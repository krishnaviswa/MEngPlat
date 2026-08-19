import { fireEvent, render, screen } from "@testing-library/react";
import { RegisterForm } from "@/components/RegisterForm";

jest.mock("../../lib/api", () => ({
  auth: {
    register: jest.fn(),
    google: jest.fn(),
    phoneRequest: jest.fn(),
    phoneVerify: jest.fn(),
  },
  storeTokens: jest.fn(),
  redirectAfterAuth: jest.fn(),
}));

describe("RegisterForm (S-092)", () => {
  it("keeps account type to customer/merchant and hides SMS until Mobile OTP is chosen", () => {
    render(<RegisterForm />);
    const typeSelect = screen.getByLabelText(/account type/i) as HTMLSelectElement;
    expect(Array.from(typeSelect.options).map((o) => o.value)).toEqual(["customer", "merchant"]);
    expect(screen.getByPlaceholderText("Email")).toBeInTheDocument();
    expect(screen.queryByLabelText(/mobile number/i)).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("radio", { name: /mobile otp/i }));
    expect(screen.queryByPlaceholderText("Email")).not.toBeInTheDocument();
    expect(screen.getByLabelText(/mobile number/i)).toBeInTheDocument();
  });
});
