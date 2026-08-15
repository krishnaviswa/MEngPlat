import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { PhoneOtpPanel } from "@/components/PhoneOtpPanel";
import { auth, storeTokens } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { phoneRequest: jest.fn(), phoneVerify: jest.fn() },
  storeTokens: jest.fn(),
}));

const requestMock = auth.phoneRequest as jest.Mock;
const verifyMock = auth.phoneVerify as jest.Mock;

describe("PhoneOtpPanel", () => {
  const originalLocation = window.location;

  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(window, "location", {
      value: { ...originalLocation, href: "" },
      writable: true,
    });
  });

  it("requests a code then verifies and stores tokens", async () => {
    requestMock.mockResolvedValue({ message: "sent" });
    verifyMock.mockResolvedValue({ access_token: "a", refresh_token: "r" });
    render(<PhoneOtpPanel fullName="Ada" role="customer" onError={jest.fn()} />);
    fireEvent.change(screen.getByLabelText(/mobile number/i), { target: { value: "9876543210" } });
    fireEvent.click(screen.getByRole("button", { name: /send sms code/i }));
    await waitFor(() => expect(requestMock).toHaveBeenCalledWith("+919876543210"));
    fireEvent.change(screen.getByLabelText(/sms code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify and sign in/i }));
    await waitFor(() =>
      expect(verifyMock).toHaveBeenCalledWith({
        phone: "+919876543210",
        code: "123456",
        full_name: "Ada",
        role: "customer",
      }),
    );
    expect(storeTokens).toHaveBeenCalled();
  });
});
