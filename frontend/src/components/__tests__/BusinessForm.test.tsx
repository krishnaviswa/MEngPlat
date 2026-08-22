import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { BusinessForm } from "@/components/BusinessForm";
import { businesses } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  businesses: {
    categoriesAll: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    requestAddressOtp: jest.fn(),
  },
}));

jest.mock("../../lib/countryState", () => ({
  getCountries: () => [
    { code: "IN", name: "India" },
    { code: "US", name: "United States" },
    { code: "SG", name: "Singapore" },
  ],
  getStatesForCountry: (countryCode: string) => {
    if (countryCode === "IN") {
      return [
        { code: "TN", name: "Tamil Nadu" },
        { code: "KA", name: "Karnataka" },
      ];
    }
    if (countryCode === "US") {
      return [
        { code: "CA", name: "California" },
        { code: "NY", name: "New York" },
      ];
    }
    return [];
  },
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

const sampleCategory = { id: "cat-1", name: "Cafe", slug: "cafe" };

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

  // S-084 AC3: Country is a <select> defaulting to India ("IN").
  it("renders Country as a select defaulting to India (S-084 AC3)", async () => {
    render(<BusinessForm mode="create" />);
    const country = await screen.findByLabelText(/^country$/i);
    expect(country.tagName).toBe("SELECT");
    expect((country as HTMLSelectElement).value).toBe("IN");
    expect(screen.getByRole("option", { name: "India" })).toBeInTheDocument();
  });

  // S-084 AC4: State options belong to the selected country.
  it("populates State options from the selected country (S-084 AC4)", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/^state$/i);
    expect(screen.getByRole("option", { name: "Tamil Nadu" })).toBeInTheDocument();
    expect(screen.queryByRole("option", { name: "California" })).not.toBeInTheDocument();
  });

  // S-084 AC5: changing Country clears State and repopulates options.
  it("clears State and repopulates options when Country changes (S-084 AC5)", async () => {
    render(<BusinessForm mode="create" />);
    const state = (await screen.findByLabelText(/^state$/i)) as HTMLSelectElement;
    fireEvent.change(state, { target: { value: "TN" } });
    expect(state.value).toBe("TN");

    fireEvent.change(screen.getByLabelText(/^country$/i), { target: { value: "US" } });
    expect((screen.getByLabelText(/^state$/i) as HTMLSelectElement).value).toBe("");
    expect(screen.getByRole("option", { name: "California" })).toBeInTheDocument();
    expect(screen.queryByRole("option", { name: "Tamil Nadu" })).not.toBeInTheDocument();
  });

  // S-084 AC6: matching stored state is pre-selected on edit load.
  it("pre-selects a stored State that matches the country's options (S-084 AC6)", async () => {
    categoriesAllMock.mockResolvedValue([sampleCategory]);
    render(<BusinessForm mode="edit" business={existingBusiness} />);
    await waitFor(() => expect((screen.getByLabelText(/^state$/i) as HTMLSelectElement).value).toBe("TN"));
    expect((screen.getByLabelText(/^country$/i) as HTMLSelectElement).value).toBe("IN");
  });

  // S-084 AC7: unmatched legacy state shows the placeholder, does not block the form.
  it("shows an unselected State placeholder for unmatched legacy data (S-084 AC7)", async () => {
    categoriesAllMock.mockResolvedValue([sampleCategory]);
    render(
      <BusinessForm
        mode="edit"
        business={{ ...existingBusiness, state: "Tamil Nadu" }}
      />,
    );
    await waitFor(() => expect(screen.getByLabelText(/business name/i)).toHaveValue("Existing Shop"));
    expect((screen.getByLabelText(/^state$/i) as HTMLSelectElement).value).toBe("");
    expect(screen.getByRole("option", { name: /select a state/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save changes/i })).toBeEnabled();
  });

  // S-084 AC1/AC2: street address is plain text; lookup UI is gone; typing does not call maps.
  it("treats street address as a plain field with no lookup UI or network calls (S-084 AC1/AC2)", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    fireEvent.change(screen.getByLabelText(/street address/i), { target: { value: "1 Main Street" } });

    expect(screen.queryByRole("listbox")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /look up address/i })).not.toBeInTheDocument();
    expect(screen.queryByText(/nominatim/i)).not.toBeInTheDocument();
  });

  // S-084 AC8: city stays a text input.
  it("keeps City as free text (S-084 AC8)", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    expect(screen.getByLabelText(/^city/i).tagName).toBe("INPUT");
  });

  // No manual Latitude/Longitude inputs -- no one used them by hand; the fields
  // stay in the data model/API for whatever future geocode mechanism sets them.
  it("has no manual Latitude/Longitude inputs", async () => {
    render(<BusinessForm mode="create" />);
    await screen.findByLabelText(/required field legend/i);
    expect(screen.queryByLabelText(/^latitude$/i)).not.toBeInTheDocument();
    expect(screen.queryByLabelText(/^longitude$/i)).not.toBeInTheDocument();
  });

  // S-084 AC10: a country-only edit is included in the PATCH payload.
  it("includes the new Country in businesses.update on edit (S-084 AC10)", async () => {
    categoriesAllMock.mockResolvedValue([sampleCategory]);
    updateMock.mockResolvedValue({ ...existingBusiness, country: "US" });
    render(<BusinessForm mode="edit" business={existingBusiness} />);
    await waitFor(() => expect(screen.getByLabelText(/business name/i)).toHaveValue("Existing Shop"));
    fireEvent.change(screen.getByLabelText(/^country$/i), { target: { value: "US" } });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));

    await waitFor(() => expect(updateMock).toHaveBeenCalled());
    expect(updateMock.mock.calls[0][1]).toMatchObject({ country: "US" });
  });

  // S-073 AC4: creating a business never requires an OTP/re-verification step.
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
