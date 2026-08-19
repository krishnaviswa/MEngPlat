/**
 * Bundled ISO-3166 country + subdivision lists (ADR-015).
 *
 * Imports Country and State from package subpaths so webpack never pulls
 * `city.json` (~8MB). City stays free text on the business form.
 */
import Country from "country-state-city/lib/country";
import { getStatesOfCountry } from "country-state-city/lib/state";

export type CountryOption = { code: string; name: string };
export type StateOption = { code: string; name: string };

export function getCountries(): CountryOption[] {
  return Country.getAllCountries()
    .map((c) => ({ code: c.isoCode, name: c.name }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function getStatesForCountry(countryCode: string): StateOption[] {
  if (!countryCode.trim()) return [];
  return getStatesOfCountry(countryCode).map((s) => ({
    code: s.isoCode,
    name: s.name,
  }));
}
