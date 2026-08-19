import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/media_url.dart';
import '../../ui/widgets.dart';
import '../businesses/business_card.dart';
import '../reviews/rating_stars.dart';
import '../theme/theme_toggle_button.dart';
import 'home_providers.dart';
import 'social_proof_data.dart';

/// Public marketing home (S-064 / Tier 5). Section order matches web `/`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _explore({String? q, String? city, String? category}) {
    final params = <String, String>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (city != null && city.isNotEmpty) 'city': city,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final uri = Uri(path: '/businesses', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final payload = ref.watch(homePayloadProvider);

    return Scaffold(
      key: const Key('homeScreen'),
      appBar: AppBar(title: const Text('MerchantHub'), actions: const [ThemeToggleButton()]),
      body: payload.when(
        loading: () => const MhSkeleton(),
        error: (error, _) => Center(
          child: MhError(error: error, onRetry: () => ref.invalidate(homePayloadProvider)),
        ),
        data: (home) => MhCanvas(
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _HeroSection(
              searchController: _searchController,
              onExplore: () => _explore(q: _searchController.text.trim()),
              onRegister: () => context.go('/register'),
            ),
            _SocialProofRail(entries: home.socialProof),
            const _ProblemSection(),
            if (home.stats != null) _TrustMetrics(stats: home.stats!),
            if (home.cities.isNotEmpty)
              _CityIndex(cities: home.cities, onTap: (city) => _explore(city: city)),
            if (home.categories.isNotEmpty)
              _CategoryIndex(
                categories: home.categories,
                onTap: (slug) => _explore(category: slug),
              ),
            _FeaturedGrid(
              businesses: home.featured,
              featuredCity: home.featuredCity,
              loadError: home.loadError,
              onViewAll: () => _explore(city: home.featuredCity),
              onBusinessTap: (slug) => context.push('/businesses/$slug'),
            ),
            if (home.voices.isNotEmpty) _ReviewVoices(items: home.voices),
            const _HowItWorks(),
            _MerchantCta(
              onRegister: () => context.go('/register'),
              onSignIn: () => context.go('/login'),
            ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.searchController,
    required this.onExplore,
    required this.onRegister,
  });

  final TextEditingController searchController;
  final VoidCallback onExplore;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('homeHero'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MERCHANTHUB',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Local businesses, reviewed with clarity',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find neighborhood shops with photos, ratings, and AI-suggested insights — never presented as definitive judgments.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('homeSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onExplore(),
            style: const TextStyle(color: MhTokens.ink),
            decoration: InputDecoration(
              hintText: 'Try café, salon, pharmacy, Chrompet…',
              hintStyle: TextStyle(color: MhTokens.ink.withValues(alpha: 0.45)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('homeExploreButton'),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0369A1)),
                onPressed: onExplore,
                child: const Text('Explore listings'),
              ),
              OutlinedButton(
                key: const Key('homeRegisterButton'),
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('List your business'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialProofRail extends StatelessWidget {
  const _SocialProofRail({required this.entries});

  final List<SocialProofEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('socialProofRail'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'BUSINESSES USING MERCHANTHUB',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 168,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final entry = entries[i];
                final image = entry.imageUrl;
                return SizedBox(
                  width: 160,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: image == null
                              ? Center(
                                  child: Text(
                                    entry.initial,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                )
                              : Image.network(
                                  resolveMediaUrl(image),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(child: Text(entry.initial)),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemSection extends StatelessWidget {
  const _ProblemSection();

  static const _points = [
    (
      n: '01',
      title: 'Your reviews are scattered',
      body:
          "Google reviews, word of mouth, in-person feedback — there's no single place to see it all.",
    ),
    (
      n: '02',
      title: "You don't know what's actually working",
      body: "A star average alone doesn't say which service, staff member, or product is driving satisfaction.",
    ),
    (
      n: '03',
      title: "Vague reviews don't help anyone",
      body:
          '"Good place" tells future customers and the owner nothing actionable — MerchantHub\'s guided review flow fixes that at the source.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('problemSection'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            'The problem with local reviews today',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'MerchantHub is built around three specific gaps we kept seeing',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _points.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MhCard(
                accent: const [MhAccent.coral, MhAccent.amber, MhAccent.violet][i],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _points[i].n,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.4,
                            color: const [MhAccent.coral, MhAccent.amber, MhAccent.violet][i]
                                .inkFor(Theme.of(context).brightness),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_points[i].title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(_points[i].body, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrustMetrics extends StatelessWidget {
  const _TrustMetrics({required this.stats});

  final PublicPlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Approved businesses', stats.totalBusinesses),
      ('Active reviews', stats.totalReviews),
      ('Categories', stats.totalCategories),
      ('Cities covered', stats.totalCities),
    ];
    return Padding(
      key: const Key('trustMetrics'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final item in items)
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CityIndex extends StatelessWidget {
  const _CityIndex({required this.cities, required this.onTap});

  final List<CityIndexItem> cities;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('cityIndex'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Neighborhoods on the map', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Jump into a city with approved listings — counts update from the live catalog.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          for (final city in cities)
            ListTile(
              key: Key('cityIndex-${city.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(city.name),
              trailing: Text('${city.count} ${city.count == 1 ? 'listing' : 'listings'}'),
              onTap: () => onTap(city.name),
            ),
        ],
      ),
    );
  }
}

class _CategoryIndex extends StatelessWidget {
  const _CategoryIndex({required this.categories, required this.onTap});

  final List<CategoryIndexItem> categories;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('categoryIndex'),
      width: double.infinity,
      color: scheme.inverseSurface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onInverseSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter search by what you need — cafés, clinics, salons, repair shops, and more.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
          ),
          const SizedBox(height: 8),
          for (final item in categories)
            Material(
              color: Colors.transparent,
              child: ListTile(
                key: Key('categoryIndex-${item.category.slug}'),
                contentPadding: EdgeInsets.zero,
                title: Text(item.category.name, style: TextStyle(color: scheme.onInverseSurface)),
                trailing: Text(
                  item.count > 0 ? '${item.count}' : '—',
                  style: TextStyle(color: scheme.onInverseSurface),
                ),
                onTap: () => onTap(item.category.slug),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedGrid extends StatelessWidget {
  const _FeaturedGrid({
    required this.businesses,
    required this.featuredCity,
    required this.loadError,
    required this.onViewAll,
    required this.onBusinessTap,
  });

  final List<BusinessResponse> businesses;
  final String? featuredCity;
  final String? loadError;
  final VoidCallback onViewAll;
  final ValueChanged<String> onBusinessTap;

  @override
  Widget build(BuildContext context) {
    final title = featuredCity != null ? 'Explore $featuredCity' : 'Featured businesses';
    return Padding(
      key: const Key('featuredGrid'),
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Photos, ratings, and optional AI suggestions drawn from live reviews',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onViewAll, child: Text(featuredCity != null ? 'View all in $featuredCity' : 'View all')),
              ],
            ),
          ),
          if (businesses.isNotEmpty)
            for (final business in businesses) ...[
              BusinessCard(business: business, onTap: () => onBusinessTap(business.slug)),
              if (business.aiMerchantSummary != null && business.aiMerchantSummary!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Why locals love it (suggestion): ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: business.aiMerchantSummary),
                      ],
                    ),
                  ),
                ),
            ]
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loadError == null ? 'No businesses loaded yet.' : 'Could not load businesses from the API. $loadError',
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewVoices extends StatelessWidget {
  const _ReviewVoices({required this.items});

  final List<ReviewVoiceItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('reviewVoices'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voices from the neighborhood', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Recent reviews from real listings — AI notes are suggestions, not definitive judgments.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RatingStars(rating: item.review.rating),
                      const SizedBox(width: 8),
                      Text(item.review.rating.toStringAsFixed(1)),
                    ],
                  ),
                  if (item.review.title != null && item.review.title!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.review.title!, style: Theme.of(context).textTheme.titleMedium),
                  ],
                  const SizedBox(height: 4),
                  Text(item.review.body, maxLines: 4, overflow: TextOverflow.ellipsis),
                  if (item.review.aiAnalysis?.summary != null) ...[
                    const SizedBox(height: 8),
                    Text('In a nutshell (suggestion): ${item.review.aiAnalysis!.summary}'),
                  ],
                  TextButton(
                    onPressed: () => GoRouter.of(context).push('/businesses/${item.business.slug}'),
                    child: Text(
                      item.business.city.isEmpty
                          ? item.business.name
                          : '${item.business.name} · ${item.business.city}',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('01', 'Search', 'Find shops by name, city, or category — with maps and hours when available.'),
    ('02', 'Compare', 'Read ratings and reviews. AI summaries are suggestions to help you scan faster.'),
    ('03', 'Support local', 'Visit, leave feedback, and help independent businesses grow with clearer signal.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('howItWorks'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Text('How it works', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Three steps from discovery to supporting the shops around you',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final step in _steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.4,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(step.$2, style: Theme.of(context).textTheme.titleLarge),
                  Text(step.$3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MerchantCta extends StatelessWidget {
  const _MerchantCta({required this.onRegister, required this.onSignIn});

  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('merchantCta'),
      width: double.infinity,
      color: scheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOR BUSINESS OWNERS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.6,
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn reviews into AI-suggested next steps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Claim your listing, reply to customers, and read sentiment suggestions on your dashboard — always framed as guidance, not a final verdict.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onPrimary,
                  foregroundColor: scheme.primary,
                ),
                onPressed: onRegister,
                child: const Text('Create a merchant account'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: scheme.onPrimary),
                onPressed: onSignIn,
                child: const Text('Sign in to dashboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
