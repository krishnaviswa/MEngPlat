import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MerchantNationalIdCard } from "@/components/MerchantNationalIdCard";
import { auth } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  auth: { updateMe: jest.fn() },
}));

const updateMock = auth.updateMe as jest.Mock;

describe("MerchantNationalIdCard", () => {
  it("prompts merchants who have no ID and saves PAN/Aadhaar", async () => {
    updateMock.mockResolvedValue({
      id: "u1",
      role: "merchant",
      full_name: "Merch",
      email: "m@example.com",
      national_id_type: "aadhaar",
      national_id_number: "123412341234",
    });
    const onSaved = jest.fn();
    render(
      <MerchantNationalIdCard
        user={{ id: "u1", role: "merchant", full_name: "Merch", email: "m@example.com" }}
        onSaved={onSaved}
      />,
    );
    expect(screen.getByText(/Add PAN, Aadhaar/i)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText(/national id type/i), { target: { value: "aadhaar" } });
    fireEvent.change(screen.getByLabelText(/national id number/i), { target: { value: "123412341234" } });
    fireEvent.click(screen.getByRole("button", { name: /save national id/i }));
    await waitFor(() => expect(updateMock).toHaveBeenCalled());
    expect(onSaved).toHaveBeenCalled();
  });
});
