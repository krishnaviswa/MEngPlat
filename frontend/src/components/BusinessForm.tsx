"use client";

import { useEffect, useState } from "react";
import { businesses, maps } from "@/lib/api";
import type { Business, BusinessCreateInput, Category } from "@/lib/api";

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

interface BusinessFormProps {
  mode: "create" | "edit";
  business?: Business;
  onSuccess?: (business: Business) => void;
}

/** BusinessForm — shared create/edit form for merchant-owned businesses. */
export function BusinessForm({ mode, business, onSuccess }: BusinessFormProps) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [form, setForm] = useState<BusinessFormValues>(emptyValues);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [geocodeLoading, setGeocodeLoading] = useState(false);
  const [geocodeMessage, setGeocodeMessage] = useState("");

  useEffect(() => {
    businesses.categoriesAll().then(setCategories).catch(() => setCategories([]));
  }, []);

  useEffect(() => {
    if (mode === "edit" && business && categories.length > 0) {
      setForm(businessToFormValues(business, categories));
    }
  }, [mode, business, categories]);

  function toggleCategory(id: string) {
    setForm((prev) => ({
      ...prev,
      category_ids: prev.category_ids.includes(id)
        ? prev.category_ids.filter((c) => c !== id)
        : [...prev.category_ids, id],
    }));
  }

  async function handleGeocode() {
    const parts = [form.address, form.city, form.state, form.postal_code, form.country].filter(Boolean);
    const query = parts.join(", ");
    if (!query.trim()) {
      setGeocodeMessage("");
      setError("Enter an address before looking up coordinates.");
      return;
    }

    setGeocodeLoading(true);
    setGeocodeMessage("");
    setError("");
    try {
      const result = await maps.geocode(query);
      if (result.latitude != null && result.longitude != null) {
        setForm((prev) => ({
          ...prev,
          latitude: String(result.latitude),
          longitude: String(result.longitude),
        }));
        setGeocodeMessage(result.display_name ?? "Location found.");
      } else {
        setGeocodeMessage(result.message);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Geocode failed");
    } finally {
      setGeocodeLoading(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const payload = toPayload(form);
      const saved =
        mode === "create"
          ? await businesses.create(payload)
          : await businesses.update(business!.id, payload);
      onSuccess?.(saved);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Save failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-xl border bg-white p-6 shadow-sm">
      <h2 className="text-lg font-semibold">{mode === "create" ? "Register your business" : "Edit business"}</h2>
      {mode === "create" && (
        <p className="text-sm text-gray-600">
          New listings start as <strong>pending</strong> until an admin approves them.
        </p>
      )}
      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-gray-700">Business name *</span>
          <input
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-gray-700">Description</span>
          <textarea
            rows={3}
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-gray-700">Street address *</span>
          <input
            required
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">City *</span>
          <input
            required
            value={form.city}
            onChange={(e) => setForm({ ...form, city: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">State</span>
          <input
            value={form.state}
            onChange={(e) => setForm({ ...form, state: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">Postal code</span>
          <input
            value={form.postal_code}
            onChange={(e) => setForm({ ...form, postal_code: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">Country</span>
          <input
            value={form.country}
            onChange={(e) => setForm({ ...form, country: e.target.value })}
            placeholder="IN"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">Phone</span>
          <input
            type="tel"
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">Email</span>
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-gray-700">Website</span>
          <input
            type="url"
            value={form.website}
            onChange={(e) => setForm({ ...form, website: e.target.value })}
            placeholder="https://"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-gray-700">Latitude</span>
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
          <span className="text-sm font-medium text-gray-700">Longitude</span>
          <input
            type="number"
            step="any"
            value={form.longitude}
            onChange={(e) => setForm({ ...form, longitude: e.target.value })}
            placeholder="e.g. 80.14"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </label>
        <div className="flex flex-col gap-2 sm:col-span-2">
          <button
            type="button"
            onClick={handleGeocode}
            disabled={geocodeLoading}
            className="w-fit rounded border border-brand-200 bg-brand-50 px-4 py-2 text-sm font-medium text-brand-800 hover:bg-brand-100 disabled:opacity-50"
          >
            {geocodeLoading ? "Looking up…" : "Look up address"}
          </button>
          {geocodeMessage && <p className="text-sm text-gray-600">{geocodeMessage}</p>}
          <p className="text-xs text-gray-500">
            Geocoding uses OpenStreetMap Nominatim on button click only (not while typing).
          </p>
        </div>
      </div>

      {categories.length > 0 && (
        <fieldset>
          <legend className="text-sm font-medium text-gray-700">Categories</legend>
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            {categories.map((cat) => (
              <label key={cat.id} className="flex items-center gap-2 text-sm text-gray-700">
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

      <div className="flex gap-3 pt-2">
        <button
          type="submit"
          disabled={loading}
          className="rounded bg-brand-600 px-4 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {loading ? "Saving..." : mode === "create" ? "Submit for approval" : "Save changes"}
        </button>
        <a href="/merchant/dashboard" className="rounded border px-4 py-2 text-gray-700 hover:bg-gray-50">
          Cancel
        </a>
      </div>
    </form>
  );
}
