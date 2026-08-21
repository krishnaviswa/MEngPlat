/// Bundled ISO-3166 country + subdivision lists (S-084 mobile parity).
/// City stays typed or picked from known cities — not a full world city file.
class CountryOption {
  const CountryOption(this.code, this.name);
  final String code;
  final String name;
}

class StateOption {
  const StateOption(this.code, this.name);
  final String code;
  final String name;
}

List<CountryOption> getCountries() => List<CountryOption>.unmodifiable(_countries);

List<StateOption> getStatesForCountry(String countryCode) {
  return List<StateOption>.unmodifiable(_states[countryCode.trim().toUpperCase()] ?? const []);
}

/// Resolve a stored value that may be an ISO code or a display name.
String? matchingStateCode(String countryCode, String? stored) {
  if (stored == null || stored.trim().isEmpty) return null;
  final states = getStatesForCountry(countryCode);
  final needle = stored.trim();
  for (final state in states) {
    if (state.code.toLowerCase() == needle.toLowerCase() ||
        state.name.toLowerCase() == needle.toLowerCase()) {
      return state.code;
    }
  }
  return null;
}

const _indiaCities = <String>[
  'Ahmedabad',
  'Bengaluru',
  'Chennai',
  'Coimbatore',
  'Delhi',
  'Hyderabad',
  'Jaipur',
  'Kochi',
  'Kolkata',
  'Lucknow',
  'Madurai',
  'Mumbai',
  'Pune',
  'Surat',
];

List<String> citySuggestions({required String countryCode, required List<String> fromApi, String? current}) {
  final seen = <String>{};
  final out = <String>[];
  void add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    final key = value.toLowerCase();
    if (seen.add(key)) out.add(value);
  }

  for (final city in fromApi) {
    add(city);
  }
  if (countryCode.toUpperCase() == 'IN') {
    for (final city in _indiaCities) {
      add(city);
    }
  }
  add(current ?? '');
  out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

const _countries = <CountryOption>[
  CountryOption('IN', 'India'),
  CountryOption('US', 'United States'),
  CountryOption('GB', 'United Kingdom'),
  CountryOption('AE', 'United Arab Emirates'),
  CountryOption('AU', 'Australia'),
  CountryOption('BD', 'Bangladesh'),
  CountryOption('CA', 'Canada'),
  CountryOption('DE', 'Germany'),
  CountryOption('FR', 'France'),
  CountryOption('ID', 'Indonesia'),
  CountryOption('IE', 'Ireland'),
  CountryOption('MY', 'Malaysia'),
  CountryOption('NP', 'Nepal'),
  CountryOption('NZ', 'New Zealand'),
  CountryOption('PK', 'Pakistan'),
  CountryOption('QA', 'Qatar'),
  CountryOption('SA', 'Saudi Arabia'),
  CountryOption('SG', 'Singapore'),
  CountryOption('LK', 'Sri Lanka'),
  CountryOption('ZA', 'South Africa'),
];

const _states = <String, List<StateOption>>{
  'IN': [
    StateOption('AN', 'Andaman and Nicobar Islands'),
    StateOption('AP', 'Andhra Pradesh'),
    StateOption('AR', 'Arunachal Pradesh'),
    StateOption('AS', 'Assam'),
    StateOption('BR', 'Bihar'),
    StateOption('CH', 'Chandigarh'),
    StateOption('CT', 'Chhattisgarh'),
    StateOption('DH', 'Dadra and Nagar Haveli and Daman and Diu'),
    StateOption('DL', 'Delhi'),
    StateOption('GA', 'Goa'),
    StateOption('GJ', 'Gujarat'),
    StateOption('HR', 'Haryana'),
    StateOption('HP', 'Himachal Pradesh'),
    StateOption('JK', 'Jammu and Kashmir'),
    StateOption('JH', 'Jharkhand'),
    StateOption('KA', 'Karnataka'),
    StateOption('KL', 'Kerala'),
    StateOption('LA', 'Ladakh'),
    StateOption('LD', 'Lakshadweep'),
    StateOption('MP', 'Madhya Pradesh'),
    StateOption('MH', 'Maharashtra'),
    StateOption('MN', 'Manipur'),
    StateOption('ML', 'Meghalaya'),
    StateOption('MZ', 'Mizoram'),
    StateOption('NL', 'Nagaland'),
    StateOption('OR', 'Odisha'),
    StateOption('PY', 'Puducherry'),
    StateOption('PB', 'Punjab'),
    StateOption('RJ', 'Rajasthan'),
    StateOption('SK', 'Sikkim'),
    StateOption('TN', 'Tamil Nadu'),
    StateOption('TG', 'Telangana'),
    StateOption('TR', 'Tripura'),
    StateOption('UP', 'Uttar Pradesh'),
    StateOption('UT', 'Uttarakhand'),
    StateOption('WB', 'West Bengal'),
  ],
  'US': [
    StateOption('AL', 'Alabama'),
    StateOption('AK', 'Alaska'),
    StateOption('AZ', 'Arizona'),
    StateOption('CA', 'California'),
    StateOption('CO', 'Colorado'),
    StateOption('FL', 'Florida'),
    StateOption('GA', 'Georgia'),
    StateOption('IL', 'Illinois'),
    StateOption('MA', 'Massachusetts'),
    StateOption('NY', 'New York'),
    StateOption('TX', 'Texas'),
    StateOption('WA', 'Washington'),
  ],
  'GB': [
    StateOption('ENG', 'England'),
    StateOption('NIR', 'Northern Ireland'),
    StateOption('SCT', 'Scotland'),
    StateOption('WLS', 'Wales'),
  ],
  'AU': [
    StateOption('NSW', 'New South Wales'),
    StateOption('QLD', 'Queensland'),
    StateOption('SA', 'South Australia'),
    StateOption('TAS', 'Tasmania'),
    StateOption('VIC', 'Victoria'),
    StateOption('WA', 'Western Australia'),
  ],
  'CA': [
    StateOption('AB', 'Alberta'),
    StateOption('BC', 'British Columbia'),
    StateOption('ON', 'Ontario'),
    StateOption('QC', 'Quebec'),
  ],
};
