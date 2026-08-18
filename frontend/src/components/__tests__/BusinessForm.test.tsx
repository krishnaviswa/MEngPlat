import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { BusinessForm } from "@/components/BusinessForm";
import { businesses, maps } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  businesses: {
    categoriesAll: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    requestAddressOtp: jest.fn(),
  },
  maps: { geocode: jest.fn(), autocomplete: jest.fn().mockResolvedValue([]) },
}));

jest.mock("../../components/BusinessPhotoManager", () => ({
  BusinessPhotoManager: ({ businessId }: { businessId: string }) => (
    <div data-testid="photo-manager">photo-manager:{businessId}</div>
  ),
}));

const categoriesAllMock = businesses.categoriesAll as jest.Mock;
const createMock = businesses.create as jest.Mock;
const updateMock = businesses.update as jest.Mock;
const requestAddressOtpMock = businesses.requestAddressOtp as jest.Mock;
const autocompleteMock = maps.autocomplete as jest.Mock;

function fillRequiredBaseFields() {
  fireEvent.change(screen.getByLabelText(/business name/i), { target: { value: "Test Shop" } });
  fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "1 Main St" } });
  fireEvent.change(screen.getByLabelText(/city/i), { target: { value: "Chennai" } });
}

describe("BusinessForm", () => {
  beforeEach(() => {
    categoriesAllMock.mockResolvedValue([]);
    createMock.mockReset();
    updateMock.mockReset();
    requestAddressOtpMock.mockReset();
    autocompleteMock.mockReset();
    autocompleteMock.mockResolvedValue([]);
  });

  // S-072 AC1: legend visible near the top of the form.
  it("renders a required-field legend explaining the star marker", async () => {
    render(<BusinessForm mode="create" />);
    expect(await screen.findByLabelText(/required field legend/i)).toHaveTextContent(/★.*Required field/i);
  });

  // S-072 AC2: required labels (name/address/city/email/phone) all use the same ★ marker.
  it("marks name, address, city, phone, and email with the ★ required marker", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    const requiredLabels = ["Business name", "Street address", "City", "Phone", "Email"];
    for (const label of requiredLabels) {
      const el = screen.getByText(new RegExp(label, "i")).closest("span");
      expect(el?.textContent).toContain("★");
    }
  });

  // S-072 AC3/AC4: blank email/phone blocks submission with an inline "is required" error,
  // and no API call is made.
  it("blocks submission and shows inline required errors when email and phone are blank", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fillRequiredBaseFields();
    fireEvent.click(screen.getByRole("button", { name: /submit for approval/i }));

    expect(await screen.findByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/phone number is required/i)).toBeInTheDocument();
    expect(createMock).not.toHaveBeenCalled();
  });

  // S-072 AC6: invalid (non-empty) format produces a distinct "invalid format" error, not
  // the "required" error.
  it("shows a distinct invalid-format error for a malformed (non-empty) email/phone", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fillRequiredBaseFields();
    fireEvent.change(screen.getByLabelText(/^phone/i), { target: { value: "123" } });
    fireEvent.change(screen.getByLabelText(/^email/i), { target: { value: "not-an-email" } });
    fireEvent.click(screen.getByRole("button", { name: /submit for approval/i }));

    expect(await screen.findByText(/enter a valid email address/i)).toBeInTheDocument();
    expect(screen.getByText(/enter a valid phone number/i)).toBeInTheDocument();
    expect(screen.queryByText(/email is required/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/phone number is required/i)).not.toBeInTheDocument();
    expect(createMock).not.toHaveBeenCalled();
  });

  // Happy path: valid required fields submit successfully via businesses.create.
  it("submits successfully once all required fields are valid", async () => {
    createMock.mockResolvedValue({ id: "b1", name: "Test Shop" });
    const onSuccess = jest.fn();
    render(<BusinessForm mode="create" onSuccess={onSuccess} />);
    await screen.findByLabelText(/required field legend/i);
    fillRequiredBaseFields();
    fireEvent.change(screen.getByLabelText(/^phone/i), { target: { value: "+919876500099" } });
    fireEvent.change(screen.getByLabelText(/^email/i), { target: { value: "shop@example.com" } });
    fireEvent.click(screen.getByRole("button", { name: /submit for approval/i }));

    await waitFor(() => expect(createMock).toHaveBeenCalled());
    expect(onSuccess).toHaveBeenCalledWith({ id: "b1", name: "Test Shop" });
  });

  // S-075 AC1/AC2: BusinessPhotoManager is wired into edit mode with the business id.
  it("renders BusinessPhotoManager in edit mode with the business id", async () => {
    render(
      <BusinessForm
        mode="edit"
        business={{
          id: "biz-1",
          name: "Existing Shop",
          address: "1 Main St",
          city: "Chennai",
          status: "approved",
        } as any}
      />,
    );
    expect(await screen.findByTestId("photo-manager")).toHaveTextContent("photo-manager:biz-1");
  });

  // S-075: BusinessPhotoManager is not rendered in create mode (no business id exists yet).
  it("does not render BusinessPhotoManager in create mode", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    expect(screen.queryByTestId("photo-manager")).not.toBeInTheDocument();
  });

  const existingBusiness = {
    id: "biz-1",
    name: "Existing Shop",
    address: "1 Main St",
    city: "Chennai",
    state: "TN",
    postal_code: "600001",
    country: "IN",
    phone: "+919876500099",
    status: "approved",
  } as any;

  // S-073 AC1: typing >=3 characters into the address field triggers a live,
  // debounced autocomplete lookup and renders a suggestion dropdown.
  it("shows a live suggestion dropdown once >=3 characters are typed into the address field (S-073 AC1)", async () => {
    autocompleteMock.mockResolvedValue([
      { display_name: "1 Main St, Chennai, TN, India", latitude: 13.08, longitude: 80.27, city: "Chennai", postal_code: "600001", state: "TN" },
    ]);
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "1 Main" } });

    await waitFor(() => expect(autocompleteMock).toHaveBeenCalledWith("1 Main"), { timeout: 2000 });
    expect(await screen.findByRole("listbox")).toBeInTheDocument();
    expect(screen.getByText("1 Main St, Chennai, TN, India")).toBeInTheDocument();
  });

  // S-073 AC2/AC3: selecting a suggestion pre-fills city/postal/lat/lng, and
  // those fields remain editable afterwards (not locked).
  it("pre-fills city, postal code, and coordinates on suggestion select, and leaves them editable (S-073 AC2/AC3)", async () => {
    autocompleteMock.mockResolvedValue([
      { display_name: "1 Main St, Chennai, TN, India", latitude: 13.08, longitude: 80.27, city: "Chennai", postal_code: "600001", state: "TN" },
    ]);
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "1 Main" } });
    const suggestionButton = await screen.findByRole("button", { name: "1 Main St, Chennai, TN, India" });
    fireEvent.click(suggestionButton);

    expect((screen.getByLabelText(/^city/i) as HTMLInputElement).value).toBe("Chennai");
    expect((screen.getByLabelText(/postal code/i) as HTMLInputElement).value).toBe("600001");
    expect((screen.getByLabelText(/latitude/i) as HTMLInputElement).value).toBe("13.08");
    expect((screen.getByLabelText(/longitude/i) as HTMLInputElement).value).toBe("80.27");

    // AC3: still editable -- override the pre-filled city.
    fireEvent.change(screen.getByLabelText(/^city/i), { target: { value: "Coimbatore" } });
    expect((screen.getByLabelText(/^city/i) as HTMLInputElement).value).toBe("Coimbatore");
  });

  // S-073 AC8: no suggestions returned -> dropdown doesn't appear, and the
  // existing "Look up address" button fallback still works, no dead end.
  it("falls back to the manual Look up address button when autocomplete returns no suggestions (S-073 AC8)", async () => {
    autocompleteMock.mockResolvedValue([]);
    const geocodeMock = maps.geocode as jest.Mock;
    geocodeMock.mockResolvedValue({ message: "OK", latitude: 1, longitude: 2, display_name: "Somewhere" });

    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "sparse coverage rd" } });

    await waitFor(() => expect(autocompleteMock).toHaveBeenCalled(), { timeout: 2000 });
    expect(screen.queryByRole("listbox")).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /look up address/i }));
    await waitFor(() => expect(geocodeMock).toHaveBeenCalled());
    expect(await screen.findByText("Somewhere")).toBeInTheDocument();
  });

  // S-073 AC4: creating a business (even with an address set via autocomplete)
  // never requires an OTP/re-verification step.
  it("does not require address re-verification when creating a business (S-073 AC4)", async () => {
    createMock.mockResolvedValue({ id: "b1", name: "Test Shop" });
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fillRequiredBaseFields();
    fireEvent.change(screen.getByLabelText(/^phone/i), { target: { value: "+919876500099" } });
    fireEvent.change(screen.getByLabelText(/^email/i), { target: { value: "shop@example.com" } });
    fireEvent.click(screen.getByRole("button", { name: /submit for approval/i }));

    await waitFor(() => expect(createMock).toHaveBeenCalled());
    expect(requestAddressOtpMock).not.toHaveBeenCalled();
    expect(screen.queryByLabelText(/address verification code/i)).not.toBeInTheDocument();
  });

  // S-073 AC5: the first edit to an existing business's address is allowed with
  // no OTP step (server 200s directly; requestAddressOtp is never called).
  it("allows a first address edit on an existing business with no OTP step (S-073 AC5)", async () => {
    updateMock.mockResolvedValue({ ...existingBusiness, address: "2 New St" });
    render(<BusinessForm mode="edit" business={existingBusiness} />);
    await screen.findByTestId("photo-manager");
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "2 New St" } });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));

    await waitFor(() => expect(updateMock).toHaveBeenCalled());
    expect(requestAddressOtpMock).not.toHaveBeenCalled();
    expect(screen.queryByLabelText(/address verification code/i)).not.toBeInTheDocument();
  });

  // S-073 AC6/AC7: a 2nd+ address edit that 400s "Verification code required..."
  // surfaces the inline OTP step, requests a code, and resubmits with it -- on
  // success the change is saved.
  it("shows the inline OTP step on a gated 2nd+ address edit, then saves once verified (S-073 AC6)", async () => {
    updateMock
      .mockRejectedValueOnce(new Error("Verification code required to confirm this address change"))
      .mockResolvedValueOnce({ ...existingBusiness, address: "3 Confirmed St" });
    requestAddressOtpMock.mockResolvedValue({ message: "Code sent" });

    render(<BusinessForm mode="edit" business={existingBusiness} />);
    await screen.findByTestId("photo-manager");
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "3 Confirmed St" } });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));

    expect(await screen.findByLabelText(/address verification code/i)).toBeInTheDocument();
    await waitFor(() => expect(requestAddressOtpMock).toHaveBeenCalledWith("biz-1"));

    fireEvent.change(screen.getByLabelText(/address verification code/i), { target: { value: "123456" } });
    fireEvent.click(screen.getByRole("button", { name: /verify & save/i }));

    await waitFor(() => expect(updateMock).toHaveBeenCalledTimes(2));
    expect(updateMock.mock.calls[1][1]).toMatchObject({ address_otp_code: "123456" });
  });

  // S-073 AC7: a failed/wrong OTP code leaves the address change unsaved --
  // the OTP step stays visible with an error, no silent partial success.
  it("does not save the address change when the OTP code is wrong (S-073 AC7)", async () => {
    updateMock
      .mockRejectedValueOnce(new Error("Verification code required to confirm this address change"))
      .mockRejectedValueOnce(new Error("Invalid or expired code"));
    requestAddressOtpMock.mockResolvedValue({ message: "Code sent" });

    render(<BusinessForm mode="edit" business={existingBusiness} />);
    await screen.findByTestId("photo-manager");
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "4 Bad Attempt St" } });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));
    expect(await screen.findByLabelText(/address verification code/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/address verification code/i), { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: /verify & save/i }));

    expect(await screen.findByText(/invalid or expired code/i)).toBeInTheDocument();
    expect(updateMock).toHaveBeenCalledTimes(2);
  });
});
