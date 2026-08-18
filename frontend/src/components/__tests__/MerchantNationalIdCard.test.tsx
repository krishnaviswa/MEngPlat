import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MerchantNationalIdCard } from "@/components/MerchantNationalIdCard";
import { auth, nationalId } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { updateMe: jest.fn(), me: jest.fn() },
  nationalId: { requestAadhaarMockOtp: jest.fn(), verifyAadhaarMockOtp: jest.fn() },
}));

const updateMock = auth.updateMe as jest.Mock;

describe("MerchantNationalIdCard", () => {
  it("prompts merchants who have no ID and saves PAN directly (non-Aadhaar path)", async () => {
    updateMock.mockResolvedValue({
      id: "u1",
      role: "merchant",
      full_name: "Merch",
      email: "m@example.com",
      national_id_type: "pan",
      national_id_number: "ABCDE1234F",
    });
    const onSaved = jest.fn();
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={onSaved}
      />,
    );
    expect(screen.getByText(/Add PAN, Aadhaar/i)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "pan" } });
    fireEvent.change(screen.getByLabelText("National ID number"), { target: { value: "ABCDE1234F" } });
    fireEvent.click(screen.getByRole("button", { name: /save national id/i }));
    await waitFor(() => expect(updateMock).toHaveBeenCalled());
    expect(onSaved).toHaveBeenCalled();
  });

  it("routes Aadhaar through the mock OTP step instead of saving directly (S-070)", async () => {
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={jest.fn()}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    expect(screen.getByRole("button", { name: /send verification code/i })).toBeInTheDocument();
  });

  // S-070 AC1: a structurally invalid Aadhaar (not exactly 12 digits) is blocked
  // client-side with an inline error, and the mock-OTP request is never sent.
  it("blocks submission with an inline error for a malformed Aadhaar number (S-070 AC1)", async () => {
    const requestOtpMock = nationalId.requestAadhaarMockOtp as jest.Mock;
    requestOtpMock.mockClear();
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={jest.fn()}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    fireEvent.change(screen.getByLabelText("National ID number"), { target: { value: "12345" } });
    fireEvent.click(screen.getByRole("button", { name: /send verification code/i }));

    expect(await screen.findByText(/aadhaar must be exactly 12 digits/i)).toBeInTheDocument();
    expect(requestOtpMock).not.toHaveBeenCalled();
  });

  // S-070 AC2: a structurally invalid PAN is blocked client-side with an inline
  // error before submission, mirroring the backend's structural regex.
  it("blocks submission with an inline error for a malformed PAN number (S-070 AC2)", async () => {
    updateMock.mockClear();
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={jest.fn()}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "pan" } });
    fireEvent.change(screen.getByLabelText("National ID number"), { target: { value: "NOTAVALIDPAN" } });
    fireEvent.click(screen.getByRole("button", { name: /save national id/i }));

    expect(
      await screen.findByText(/pan must be 5 letters, 4 digits, 1 letter/i),
    ).toBeInTheDocument();
    expect(updateMock).not.toHaveBeenCalled();
  });

  // S-070 AC7: the mock/demo disclaimer is visible as soon as Aadhaar is selected,
  // before the OTP step is even reached.
  it("shows the mock/demo disclaimer as soon as Aadhaar is selected (S-070 AC7)", () => {
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={jest.fn()}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    expect(screen.getByText(/mock\/demo/i)).toBeInTheDocument();
  });

  // S-070 AC3/AC4: entering a structurally valid Aadhaar and submitting reaches
  // the mock OTP step (labeled mock/demo), and a correct code saves + advances.
  it("completes the mock Aadhaar OTP flow: request -> correct code -> saved (S-070 AC3/AC4)", async () => {
    const requestOtpMock = nationalId.requestAadhaarMockOtp as jest.Mock;
    const verifyOtpMock = nationalId.verifyAadhaarMockOtp as jest.Mock;
    requestOtpMock.mockResolvedValue({ message: "Mock/demo — enter the code.", dev_code: "123456" });
    verifyOtpMock.mockResolvedValue({ message: "Aadhaar mock-verified and saved." });
    (auth.me as jest.Mock).mockResolvedValue({
      id: "u1",
      role: "merchant",
      full_name: "Merch",
      email: "m@example.com",
      national_id_type: "aadhaar",
      national_id_number: "123456789012",
    });
    const onSaved = jest.fn();

    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={onSaved}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    fireEvent.change(screen.getByLabelText("National ID number"), { target: { value: "123456789012" } });
    fireEvent.click(screen.getByRole("button", { name: /send verification code/i }));

    await waitFor(() => expect(requestOtpMock).toHaveBeenCalledWith("123456789012"));
    expect(await screen.findByText(/mock\/demo verification/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/mock aadhaar otp code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /^verify$/i }));

    await waitFor(() => expect(verifyOtpMock).toHaveBeenCalledWith("123456"));
    await waitFor(() => expect(onSaved).toHaveBeenCalled());
  });

  // S-070 AC4: an incorrect mock OTP code shows an inline error and allows retry
  // (the OTP step stays visible, not silently discarded).
  it("shows an inline error and allows retry on a wrong mock OTP code (S-070 AC4)", async () => {
    const requestOtpMock = nationalId.requestAadhaarMockOtp as jest.Mock;
    const verifyOtpMock = nationalId.verifyAadhaarMockOtp as jest.Mock;
    requestOtpMock.mockResolvedValue({ message: "Mock/demo — enter the code.", dev_code: "123456" });
    verifyOtpMock.mockRejectedValueOnce(new Error("Invalid or expired code"));

    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={jest.fn()}
      />,
    );
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    fireEvent.change(screen.getByLabelText("National ID number"), { target: { value: "123456789012" } });
    fireEvent.click(screen.getByRole("button", { name: /send verification code/i }));
    await screen.findByLabelText(/mock aadhaar otp code/i);

    fireEvent.change(screen.getByLabelText(/mock aadhaar otp code/i), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /^verify$/i }));

    expect(await screen.findByText(/invalid or expired code/i)).toBeInTheDocument();
    // Retry affordance: the code input and Verify button are still present.
    expect(screen.getByLabelText(/mock aadhaar otp code/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /^verify$/i })).toBeInTheDocument();
  });

  const baseUser = {
    id: "u1",
    role: "merchant",
    full_name: "Merch",
    email: "m@example.com",
  };

  // S-071 AC6: never-saved empty state has no reveal toggle.
  it("shows no reveal/hide toggle when there is nothing to reveal", () => {
    render(<MerchantNationalIdCard user={baseUser} onSaved={jest.fn()} />);
    expect(screen.queryByRole("button", { name: /reveal national id number/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /hide national id number/i })).not.toBeInTheDocument();
  });

  // S-071 AC3: saved national ID is masked by default (hidden), not shown in plaintext.
  it("masks a saved national ID by default", () => {
    const user = { ...baseUser, national_id_type: "pan" as const, national_id_number: "ABCDE1234F" };
    render(<MerchantNationalIdCard user={user} onSaved={jest.fn()} />);
    const input = screen.getByLabelText("National ID number") as HTMLInputElement;
    expect(input.value).not.toBe("ABCDE1234F");
    expect(input.value).toContain("234F");
    expect(input.readOnly).toBe(true);
  });

  // S-071 AC4: reveal toggle shows plaintext; clicking again re-hides it.
  it("reveals the full value on toggle click, and re-hides on a second click", () => {
    const user = { ...baseUser, national_id_type: "pan" as const, national_id_number: "ABCDE1234F" };
    render(<MerchantNationalIdCard user={user} onSaved={jest.fn()} />);
    const toggle = screen.getByRole("button", { name: /reveal national id number/i });
    fireEvent.click(toggle);
    const input = screen.getByLabelText("National ID number") as HTMLInputElement;
    expect(input.value).toBe("ABCDE1234F");
    expect(input.readOnly).toBe(false);

    fireEvent.click(screen.getByRole("button", { name: /hide national id number/i }));
    expect((screen.getByLabelText("National ID number") as HTMLInputElement).value).not.toBe("ABCDE1234F");
  });

  // S-071 AC1/AC2/AC5: local state resyncs from a fresh `user` prop (e.g. after save/refetch),
  // and resyncing also re-hides -- the one-time useState-initializer bug this slice fixes.
  it("resyncs the displayed value and re-hides when the user prop changes after mount", () => {
    const initialUser = { ...baseUser, national_id_type: "pan" as const, national_id_number: "ABCDE1234F" };
    const { rerender } = render(<MerchantNationalIdCard user={initialUser} onSaved={jest.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: /reveal national id number/i }));
    expect((screen.getByLabelText("National ID number") as HTMLInputElement).value).toBe("ABCDE1234F");

    const updatedUser = { ...baseUser, national_id_type: "pan" as const, national_id_number: "FGHIJ9876K" };
    rerender(<MerchantNationalIdCard user={updatedUser} onSaved={jest.fn()} />);

    const input = screen.getByLabelText("National ID number") as HTMLInputElement;
    expect(input.value).not.toBe("FGHIJ9876K");
    expect(input.value).toContain("876K");
    expect(input.readOnly).toBe(true);
  });

  // S-071 AC5: remounting the card (simulating navigate-away-and-back) always starts hidden,
  // even if a previous instance had been revealed.
  it("starts hidden again on a fresh mount, regardless of prior reveal state", () => {
    const user = { ...baseUser, national_id_type: "pan" as const, national_id_number: "ABCDE1234F" };
    const { unmount } = render(<MerchantNationalIdCard user={user} onSaved={jest.fn()} />);
    fireEvent.click(screen.getByRole("button", { name: /reveal national id number/i }));
    unmount();

    render(<MerchantNationalIdCard user={user} onSaved={jest.fn()} />);
    const input = screen.getByLabelText("National ID number") as HTMLInputElement;
    expect(input.value).not.toBe("ABCDE1234F");
    expect(input.readOnly).toBe(true);
  });
});
