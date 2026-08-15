import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { useSearchParams } from "next/navigation";
import { ResetPasswordForm } from "@/components/ResetPasswordForm";
import { auth } from "@/lib/api";

jest.mock("next/navigation", () => ({
  useSearchParams: jest.fn(),
}));

jest.mock("../../lib/api", () => ({
  auth: {
    resetPassword: jest.fn(),
  },
}));

const useSearchParamsMock = useSearchParams as jest.Mock;
const resetPasswordMock = auth.resetPassword as jest.Mock;

describe("ResetPasswordForm", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("shows an invalid-link message when the token query param is missing", () => {
    useSearchParamsMock.mockReturnValue(new URLSearchParams());

    render(<ResetPasswordForm />);

    expect(screen.getByText("Invalid reset link")).toBeInTheDocument();
    expect(resetPasswordMock).not.toHaveBeenCalled();
  });

  it("submits the token from the URL with the new password and shows success", async () => {
    useSearchParamsMock.mockReturnValue(new URLSearchParams("token=raw-token-abc"));
    resetPasswordMock.mockResolvedValue({ message: "Password updated. Sign in with your new password." });

    render(<ResetPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "brandnewpass123" } });
    fireEvent.change(screen.getByPlaceholderText("Confirm new password"), {
      target: { value: "brandnewpass123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /update password/i }));

    expect(await screen.findByText("Password updated")).toBeInTheDocument();
    await waitFor(() =>
      expect(resetPasswordMock).toHaveBeenCalledWith("raw-token-abc", "brandnewpass123"),
    );
    // AC: no session tokens are issued by this flow -- confirm the success
    // screen sends the user to sign in rather than treating them as logged in.
    expect(screen.getByRole("link", { name: /go to sign in/i })).toHaveAttribute("href", "/login");
  });

  it("blocks submit client-side when password and confirmation do not match", async () => {
    useSearchParamsMock.mockReturnValue(new URLSearchParams("token=raw-token-abc"));

    render(<ResetPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "brandnewpass123" } });
    fireEvent.change(screen.getByPlaceholderText("Confirm new password"), {
      target: { value: "somethingelse123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /update password/i }));

    expect(await screen.findByText("Passwords do not match")).toBeInTheDocument();
    expect(resetPasswordMock).not.toHaveBeenCalled();
  });

  it("shows the generic invalid/expired error returned by the API", async () => {
    useSearchParamsMock.mockReturnValue(new URLSearchParams("token=stale-token"));
    resetPasswordMock.mockRejectedValue(new Error("Invalid or expired reset link"));

    render(<ResetPasswordForm />);
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "brandnewpass123" } });
    fireEvent.change(screen.getByPlaceholderText("Confirm new password"), {
      target: { value: "brandnewpass123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /update password/i }));

    expect(await screen.findByText("Invalid or expired reset link")).toBeInTheDocument();
    expect(screen.queryByText("Password updated")).not.toBeInTheDocument();
  });
});
