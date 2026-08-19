"use client";

import { useEffect, useState } from "react";
import { businesses } from "@/lib/api";
import type { Business, BusinessCreateInput, BusinessUpdateInput, Category } from "@/lib/api";
import { getCountries, getStatesForCountry } from "@/lib/countryState";
import { BusinessPhotoManager } from "@/components/BusinessPhotoManager";

export type BusinessFormValues = {
  name: string;
  description: string;
  address: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  phone: string;
  email: string;
  website: string;
  latitude: string;
  longitude: string;
  category_ids: string[];
};

const emptyValues: BusinessFormValues = {
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
  latitude: "",
  longitude: "",
  category_ids: [],
};

function businessToFormValues(business: Business, categories: Category[]): BusinessFormValues {
  const categoryIds =
    business.categories
      ?.map((c) => c.id ?? categories.find((cat) => cat.slug === c.slug)?.id)
      .filter((id): id is string => Boolean(id)) ?? [];

  return {
    name: business.name,
    description: business.description ?? "",
    address: business.address,
    city: business.city,
    state: business.state ?? "",
    postal_code: business.postal_code ?? "",
    country: business.country ?? "IN",
    phone: business.phone ?? "",
    email: business.email ?? "",
    website: business.website ?? "",
    latitude: business.latitude != null ? String(business.latitude) : "",
    longitude: business.longitude != null ? String(business.longitude) : "",
    category_ids: categoryIds,
  };
}

function toUpdatePayload(values: BusinessFormValues, addressOtpCode?: string): BusinessUpdateInput {
  const payload: BusinessUpdateInput = toPayload(values);
  if (addressOtpCode) payload.address_otp_code = addressOtpCode;
  return payload;
}

function toPayload(values: BusinessFormValues): BusinessCreateInput {
  const latitude = values.latitude.trim() ? Number(values.latitude) : undefined;
  const longitude = values.longitude.trim() ? Number(values.longitude) : undefined;

  return {
    name: values.name.trim(),
    description: values.description.trim() || undefined,
    address: values.address.trim(),
    city: values.city.trim(),
    state: values.state.trim() || undefined,
    postal_code: values.postal_code.trim() || undefined,
    country: values.country.trim() || "IN",
    phone: values.phone.trim() || undefined,
    email: values.email.trim() || undefined,
    website: values.website.trim() || undefined,
    latitude: Number.isFinite(latitude) ? latitude : undefined,
    longitude: Number.isFinite(longitude) ? longitude : undefined,
    category_ids: values.category_ids,
  };
}

const EMAIL_FORMAT = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_FORMAT = /^\+?\d{7,15}$/;

interface BusinessFormProps {
  mode: "create" | "edit";
  business?: Business;
  onSuccess?: (business: Business) => void;
  /** Optional live mirror of form state, e.g. for OnboardingGuidancePanel's progress display. */
  onFormStateChange?: (values: BusinessFormValues) => void;
}

/** BusinessForm — shared create/edit form for merchant-owned businesses. */
export function BusinessForm({ mode, business, onSuccess, onFormStateChange }: BusinessFormProps) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [form, setForm] = useState<BusinessFormValues>(emptyValues);
  const [error, setError] = useState("");
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; phone?: string }>({});
  const [loading, setLoading] = useState(false);
  const [addressOtpRequired, setAddressOtpRequired] = useState(false);
  const [addressOtpCode, setAddressOtpCode] = useState("");

  useEffect(() => {
    businesses.categoriesAll().then(setCategories).catch(() => setCategories([]));
  }, []);

  useEffect(() => {
    if (mode === "edit" && business && categories.length > 0) {
      setForm(businessToFormValues(business, categories));
    }
  }, [mode, business, categories]);

  useEffect(() => {
    onFormStateChange?.(form);
    // onFormStateChange is a caller-supplied callback, not form state -- omitting it
    // from deps avoids re-firing on every parent re-render if it's an inline function.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form]);

  function toggleCategory(id: string) {
    setForm((prev) => ({
      ...prev,
      category_ids: prev.category_ids.includes(id)
        ? prev.category_ids.filter((c) => c !== id)
        : [...prev.category_ids, id],
    }));
  }

  function validateRequiredFields(): boolean {
    if (mode !== "create") return true;
    const errors: { email?: string; phone?: string } = {};
    if (!form.email.trim()) errors.email = "Email is required.";
    else if (!EMAIL_FORMAT.test(form.email.trim())) errors.email = "Enter a valid email address.";
    if (!form.phone.trim()) errors.phone = "Phone number is required.";
    else if (!PHONE_FORMAT.test(form.phone.trim())) errors.phone = "Enter a valid phone number.";
    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (!validateRequiredFields()) return;
    setLoading(true);
    try {
      const saved =
        mode === "create"
          ? await businesses.create(toPayload(form))
          : await businesses.update(business!.id, toUpdatePayload(form, addressOtpCode || undefined));
      setAddressOtpRequired(false);
      setAddressOtpCode("");
      onSuccess?.(saved);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Save failed";
      // S-073 AC6/AC7: a 2nd+ address edit 400s until an OTP is supplied. Surface
      // the inline verification step instead of a generic save error, and kick
      // off delivery of the code right away.
      if (mode === "edit" && business && /verification code required/i.test(message)) {
        setAddressOtpRequired(true);
        try {
          await businesses.requestAddressOtp(business.id);
        } catch (otpErr) {
          setError(otpErr instanceof Error ? otpErr.message : "Could not send verification code");
        }
      } else {
        setError(message);
      }
    } finally {
      setLoading(false);
    }
  }

  const countries = getCountries();
  const states = getStatesForCountry(form.country);
  const selectedState = states.some((s) => s.code === form.state) ? form.state : "";

  return (
    <form
      onSubmit={handleSubmit}
      noValidate
      className="space-y-4 rounded-xl border bg-surface-raised p-6 shadow-sm"
    >
      <h2 className="text-lg font-semibold">{mode === "create" ? "Register your business" : "Edit business"}</h2>
      {mode === "create" && (
        <p className="text-sm text-muted">
          New listings start as <strong>pending</strong> until an admin approves them.
        </p>
      )}
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700 dark:bg-red-900/40 dark:text-red-300">{error}</p>}

      <p className="text-xs text-muted" aria-label="Required field legend">
        <span className="text-red-600">★</span> Required field
      </p>

      {mode === "create" && (
        <p className="rounded border border-border bg-surface p-2 text-xs text-muted">
          National ID — set once in your{" "}
          <a href="/merchant/dashboard" className="text-brand-600 underline">
            dashboard profile
          </a>
          , required before you can submit a listing.
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-muted">
            Business name <span className="text-red-600">★</span>
          </span>
          <input
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-muted">Description</span>
          <textarea
            rows={3}
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-muted">
            Street address <span className="text-red-600">★</span>
          </span>
          <input
            required
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">
            City <span className="text-red-600">★</span>
          </span>
          <input
            required
            value={form.city}
            onChange={(e) => setForm({ ...form, city: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">State</span>
          <select
            value={selectedState}
            onChange={(e) => setForm({ ...form, state: e.target.value })}
            disabled={states.length === 0}
            className="mt-1 w-full rounded border px-3 py-2"
          >
            <option value="">{states.length === 0 ? "Not applicable" : "Select a state…"}</option>
            {states.map((s) => (
              <option key={s.code} value={s.code}>
                {s.name}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">Postal code</span>
          <input
            value={form.postal_code}
            onChange={(e) => setForm({ ...form, postal_code: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">Country</span>
          <select
            value={form.country}
            onChange={(e) => setForm({ ...form, country: e.target.value, state: "" })}
            className="mt-1 w-full rounded border px-3 py-2"
          >
            {countries.map((c) => (
              <option key={c.code} value={c.code}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">
            Phone {mode === "create" && <span className="text-red-600">★</span>}
          </span>
          <input
            type="tel"
            required={mode === "create"}
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
          {fieldErrors.phone && <p className="mt-1 text-xs text-red-600">{fieldErrors.phone}</p>}
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">
            Email {mode === "create" && <span className="text-red-600">★</span>}
          </span>
          <input
            type="email"
            required={mode === "create"}
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
          {fieldErrors.email && <p className="mt-1 text-xs text-red-600">{fieldErrors.email}</p>}
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-muted">Website</span>
          <input
            type="url"
            value={form.website}
            onChange={(e) => setForm({ ...form, website: e.target.value })}
            placeholder="https://"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">Latitude</span>
          <input
            type="number"
            step="any"
            value={form.latitude}
            onChange={(e) => setForm({ ...form, latitude: e.target.value })}
            placeholder="e.g. 12.95"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-muted">Longitude</span>
          <input
            type="number"
            step="any"
            value={form.longitude}
            onChange={(e) => setForm({ ...form, longitude: e.target.value })}
            placeholder="e.g. 80.14"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
      </div>

      {categories.length > 0 && (
        <fieldset>
          <legend className="text-sm font-medium text-muted">Categories</legend>
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            {categories.map((cat) => (
              <label key={cat.id} className="flex items-center gap-2 text-sm text-muted">
                <input
                  type="checkbox"
                  checked={form.category_ids.includes(cat.id)}
                  onChange={() => toggleCategory(cat.id)}
                />
                {cat.name}
              </label>
            ))}
          </div>
        </fieldset>
      )}

      {addressOtpRequired && (
        <div className="space-y-2 rounded border border-amber-300 bg-amber-50 p-3 dark:border-amber-800 dark:bg-amber-900/30">
          <p className="text-sm font-medium text-amber-800 dark:text-amber-300">
            Confirm this address change — enter the code sent to your business phone.
          </p>
          <input
            value={addressOtpCode}
            onChange={(e) => setAddressOtpCode(e.target.value)}
            placeholder="123456"
            aria-label="Address verification code"
            className="w-full max-w-xs rounded border px-3 py-2"
          />
        </div>
      )}

      {mode === "edit" && business && <BusinessPhotoManager businessId={business.id} />}

      <div className="flex gap-3 pt-2">
        <button
          type="submit"
          disabled={loading}
          className="rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {loading ? "Saving..." : addressOtpRequired ? "Verify & save" : mode === "create" ? "Submit for approval" : "Save changes"}
        </button>
        <a href="/merchant/dashboard" className="rounded border px-4 py-2 text-muted hover:bg-surface">
          Cancel
        </a>
      </div>
    </form>
  );
}
