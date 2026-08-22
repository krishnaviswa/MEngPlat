import { render, screen } from "@testing-library/react";
import { OnboardingGuidancePanel } from "@/components/OnboardingGuidancePanel";
import { MERCHANT_REQUIRED_FIELDS, NATIONAL_ID_DISCLAIMER } from "@/lib/onboarding-copy";
import type { BusinessFormValues } from "@/components/BusinessForm";

const emptyForm: BusinessFormValues = {
  name: "",
  description: "",
  address: "",
  city: "",
  state: "",
  postal_code: "",
  country: "IN",
  phone: "",
  email: "",
  website: "",
  category_ids: [],
};

describe("OnboardingGuidancePanel", () => {
  // S-074 AC2: lists onboarding steps at a glance.
  it("lists the onboarding steps", () => {
    render(<OnboardingGuidancePanel formState={null} />);
    expect(screen.getByText(/1\. business info/i)).toBeInTheDocument();
    expect(screen.getByText(/2\. contact details/i)).toBeInTheDocument();
    expect(screen.getByText(/3\. identity verification/i)).toBeInTheDocument();
    expect(screen.getByText(/4\. submit for admin review/i)).toBeInTheDocument();
  });

  // S-074 AC3: "what's required" summary is consistent with the ★ legend's shared copy
  // source (MERCHANT_REQUIRED_FIELDS), not a second hardcoded list.
  it("renders the shared required-fields list, matching BusinessForm's legend source", () => {
    render(<OnboardingGuidancePanel formState={null} />);
    for (const field of MERCHANT_REQUIRED_FIELDS) {
      expect(screen.getByText(field)).toBeInTheDocument();
    }
  });

  // S-074 AC4: identity-verification guidance mirrors the S-043/S-070 disclaimer verbatim.
  it("renders the shared national ID mock/demo disclaimer verbatim", () => {
    render(<OnboardingGuidancePanel formState={null} />);
    expect(screen.getByText(NATIONAL_ID_DISCLAIMER)).toBeInTheDocument();
  });

  // S-074 AC5/UX notes: renders sensibly (all steps pending) before the merchant has typed
  // anything -- formState null / empty values.
  it("shows all steps as pending when the form is empty or unset", () => {
    render(<OnboardingGuidancePanel formState={null} />);
    const badges = screen.getAllByLabelText("Pending");
    expect(badges.length).toBeGreaterThanOrEqual(2);
    expect(screen.queryAllByLabelText("Complete")).toHaveLength(0);

    render(<OnboardingGuidancePanel formState={emptyForm} />);
    expect(screen.queryAllByLabelText("Complete").length).toBe(0);
  });

  // S-074 AC5: progress reflects basic form state -- business-info step completes once
  // name/address/city are filled.
  it("marks the business-info step complete once name, address, and city are filled", () => {
    const filled: BusinessFormValues = { ...emptyForm, name: "Shop", address: "1 St", city: "Chennai" };
    render(<OnboardingGuidancePanel formState={filled} />);
    const badges = screen.getAllByLabelText("Complete");
    expect(badges.length).toBe(1);
  });

  // S-074 AC5: contact-info step completes once phone and email are both filled.
  it("marks the contact-info step complete once phone and email are filled", () => {
    const filled: BusinessFormValues = { ...emptyForm, phone: "+919876500099", email: "shop@example.com" };
    render(<OnboardingGuidancePanel formState={filled} />);
    const badges = screen.getAllByLabelText("Complete");
    expect(badges.length).toBe(1);
  });
});
