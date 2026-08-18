class SocialProofEntry {
  const SocialProofEntry({
    required this.name,
    required this.initial,
    this.logoUrl,
    this.storefrontUrl,
  });

  final String name;
  final String initial;
  final String? logoUrl;
  final String? storefrontUrl;

  String? get imageUrl => storefrontUrl ?? logoUrl;
}

/// Fallback roster — same names as web `SOCIAL_PROOF_ENTRIES` (S-047 / S-064).
const kSocialProofFallback = <SocialProofEntry>[
  SocialProofEntry(name: 'Copper Kettle Cafe', initial: 'CK'),
  SocialProofEntry(name: 'Bright Smile Dental', initial: 'BS'),
  SocialProofEntry(name: 'Chrompet Cycle Repair', initial: 'CC'),
  SocialProofEntry(name: 'Verde Salon & Spa', initial: 'VS'),
  SocialProofEntry(name: 'Anand Grocers', initial: 'AG'),
  SocialProofEntry(name: 'Pixel Print Studio', initial: 'PP'),
  SocialProofEntry(name: 'Riverside Diner', initial: 'RD'),
  SocialProofEntry(name: 'Golden Wok Kitchen', initial: 'GW'),
  SocialProofEntry(name: 'Chrompet Family Hospital', initial: 'CF'),
  SocialProofEntry(name: 'Sunrise Urgent Care', initial: 'SU'),
  SocialProofEntry(name: 'Blue Ridge Pharmacy', initial: 'BR'),
  SocialProofEntry(name: 'Nagar Medical Store', initial: 'NM'),
  SocialProofEntry(name: 'Fresh Fields Grocery', initial: 'FF'),
  SocialProofEntry(name: 'Bandra Fresh Mart', initial: 'BF'),
  SocialProofEntry(name: 'Cedar Street Salon', initial: 'CS'),
  SocialProofEntry(name: 'Glow Beauty Bar', initial: 'GB'),
  SocialProofEntry(name: 'Steel City Auto Works', initial: 'SC'),
  SocialProofEntry(name: 'Quick Fix Motors', initial: 'QF'),
  SocialProofEntry(name: 'Daily Grind Coffee House', initial: 'DG'),
  SocialProofEntry(name: 'Chai Point Corner', initial: 'CP'),
  SocialProofEntry(name: 'Harborview Bistro', initial: 'HB'),
  SocialProofEntry(name: 'Curry Leaf Kitchen', initial: 'CL'),
  SocialProofEntry(name: 'Metro Wellness Clinic', initial: 'MW'),
  SocialProofEntry(name: 'Lotus Care Hospital', initial: 'LC'),
  SocialProofEntry(name: 'Value Mart Pharmacy', initial: 'VM'),
  SocialProofEntry(name: 'Everyday Essentials Grocery', initial: 'EE'),
  SocialProofEntry(name: 'Silver Scissors Salon', initial: 'SS'),
  SocialProofEntry(name: 'Trend Cutz Studio', initial: 'TC'),
  SocialProofEntry(name: 'Precision Auto Care', initial: 'PA'),
  SocialProofEntry(name: 'Neighborhood Bike & Auto', initial: 'NB'),
];

/// Slugs seeded by `backend/scripts/seed_social_proof.py` — same order as web.
const kSocialProofSlugs = <String>[
  'copper-kettle-cafe',
  'bright-smile-dental',
  'chrompet-cycle-repair',
  'verde-salon-spa',
  'anand-grocers',
  'pixel-print-studio',
  'riverside-diner',
  'golden-wok-kitchen',
  'chrompet-family-hospital',
  'sunrise-urgent-care',
  'blue-ridge-pharmacy',
  'nagar-medical-store',
  'fresh-fields-grocery',
  'bandra-fresh-mart',
  'cedar-street-salon',
  'glow-beauty-bar',
  'steel-city-auto-works',
  'quick-fix-motors',
  'daily-grind-coffee-house',
  'chai-point-corner',
  'harborview-bistro',
  'curry-leaf-kitchen',
  'metro-wellness-clinic',
  'lotus-care-hospital',
  'value-mart-pharmacy',
  'everyday-essentials-grocery',
  'silver-scissors-salon',
  'trend-cutz-studio',
  'precision-auto-care',
  'neighborhood-bike-auto',
];

String initialsFor(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  return parts.map((w) => w[0].toUpperCase()).join();
}
