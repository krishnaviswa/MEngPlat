import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { ForgotPasswordForm } from "@/components/ForgotPasswordForm";
import { auth } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: {
    forgotPassword: jest.fn(),
  },
}));

const forgotPasswordMock = auth.forgotPassword as jest.Mock;

describe("ForgotPasswordForm", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC 2: the on-screen copy must be the same generic "if an account
  // exists..." confirmation regardless of whether the address is real.
  it("shows the generic confirmation after a successful submit", async () => {
    forgotPasswordMock.mockResolvedValue({ message: "generic" });

    render(<ForgotPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("Email"), { target: { value: "someone@example.com" } });
    fireEvent.click(screen.getByRole("button", { name: /send reset link/i }));

    expect(await screen.findByText("Check your email")).toBeInTheDocument();
    expect(
      screen.getByText("If an account exists for that email, we sent password-reset instructions."),
    ).toBeInTheDocument();
    await waitFor(() => expect(forgotPasswordMock).toHaveBeenCalledWith("someone@example.com"));
  });

  it("shows the same generic confirmation copy no matter what email was entered", async () => {
    forgotPasswordMock.mockResolvedValue({ message: "generic" });

    render(<ForgotPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("Email"), { target: { value: "unregistered@example.com" } });
    fireEvent.click(screen.getByRole("button", { name: /send reset link/i }));

    expect(await screen.findByText("Check your email")).toBeInTheDocument();
    expect(
      screen.getByText("If an account exists for that email, we sent password-reset instructions."),
    ).toBeInTheDocument();
  });

  it("surfaces a network/rate-limit error instead of the confirmation screen", async () => {
    forgotPasswordMock.mockRejectedValue(new Error("Too many requests"));

    render(<ForgotPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("Email"), { target: { value: "someone@example.com" } });
    fireEvent.click(screen.getByRole("button", { name: /send reset link/i }));

    expect(await screen.findByText("Too many requests")).toBeInTheDocument();
    expect(screen.queryByText("Check your email")).not.toBeInTheDocument();
  });

  it("links back to /login", () => {
    render(<ForgotPasswordForm />);
    expect(screen.getByText("Back to sign in").closest("a")).toHaveAttribute("href", "/login");
  });
});
