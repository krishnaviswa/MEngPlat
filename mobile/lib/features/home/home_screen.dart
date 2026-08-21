import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/media_url.dart';
import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import '../auth/post_login_path.dart';
import '../businesses/business_card.dart';
import '../businesses/search_controller.dart';
import '../reviews/rating_stars.dart';
import '../theme/theme_toggle_button.dart';
import 'home_providers.dart';
import 'social_proof_data.dart';

enum _BrowseMode { category, neighborhood }

/// Compact mobile home (S-114, S-116). Web `/` keeps the long marketing page.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _BrowseMode? _browseExpanded;

  void _explore({String? q, String? city, String? category}) {
    final params = <String, String>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (city != null && city.isNotEmpty) 'city': city,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final uri = Uri(path: '/businesses', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  void _listBusiness() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      context.go('/register');
      return;
    }
    if (user.role == UserRole.merchant) {
      context.go('/merchant/businesses/new');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('listBusinessCustomerDialog'),
        title: const Text('List a business'),
        content: const Text(
          'Shop tools need a merchant login. Sign out and register as a merchant.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = ref.watch(homePayloadProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

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
            if (user != null)
              _SignedInBanner(
                user: user,
                onOpenHub: () => context.go(hubPathFor(user.role)),
              ),
            _HeroSection(
              onExplore: (q) => _explore(q: q),
              onListBusiness: _listBusiness,
              onSuggestionTap: (business) => context.push('/businesses/${business.slug}'),
            ),
            _SocialProofRail(entries: home.socialProof),
            if (home.cities.isNotEmpty || home.categories.isNotEmpty)
              _BrowseIndex(
                expanded: _browseExpanded,
                cities: home.cities,
                categories: home.categories,
                onExpand: (mode) => setState(() => _browseExpanded = mode),
                onCity: (city) => _explore(city: city),
                onCategory: (slug) => _explore(category: slug),
              ),
            _FeaturedGrid(
              businesses: home.featured,
              featuredCity: home.featuredCity,
              loadError: home.loadError,
              onViewAll: () => _explore(city: home.featuredCity),
              onBusinessTap: (slug) => context.push('/businesses/$slug'),
            ),
            if (home.voices.isNotEmpty) _ReviewVoices(items: home.voices),
            if (home.stats != null) _TrustMetrics(stats: home.stats!),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _SignedInBanner extends StatelessWidget {
  const _SignedInBanner({required this.user, required this.onOpenHub});

  final UserResponse user;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('signedInBanner'),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Signed in as ${user.fullName} · ${roleLabel(user.role)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
            TextButton(
              key: const Key('openHubButton'),
              onPressed: onOpenHub,
              child: Text(user.role == UserRole.merchant ? 'Open Shop' : user.role == UserRole.customer ? 'Explore' : 'Open my hub'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerStatefulWidget {
  const _HeroSection({
    required this.onExplore,
    required this.onListBusiness,
    required this.onSuggestionTap,
  });

  final ValueChanged<String> onExplore;
  final VoidCallback onListBusiness;
  final ValueChanged<BusinessResponse> onSuggestionTap;

  @override
  ConsumerState<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<_HeroSection> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typed = _searchController.text.trim();
    final search = ref.watch(searchControllerProvider);
    final suggestions = typed.length >= 2
        ? (search.valueOrNull?.items ?? const <BusinessResponse>[])
        : const <BusinessResponse>[];

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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find local shops',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos and ratings. AI is a suggestion.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('homeSearchField'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              if (value.trim().length >= 2) {
                ref.read(searchControllerProvider.notifier).setQueryText(value);
              }
              setState(() {});
            },
            onSubmitted: (_) => widget.onExplore(_searchController.text.trim()),
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
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              key: const Key('homeSearchSuggestions'),
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  for (final business in suggestions.take(6))
                    ListTile(
                      key: Key('homeSearchSuggestion-${business.slug}'),
                      dense: true,
                      title: Text(business.name, style: const TextStyle(color: MhTokens.ink)),
                      subtitle: Text(
                        '${business.city}${business.categories?.isNotEmpty == true ? ' · ${business.categories!.first.name}' : ''}',
                        style: TextStyle(color: MhTokens.ink.withValues(alpha: 0.65)),
                      ),
                      onTap: () => widget.onSuggestionTap(business),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('homeExploreButton'),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0369A1)),
                onPressed: () => widget.onExplore(_searchController.text.trim()),
                child: const Text('Explore'),
              ),
              OutlinedButton(
                key: const Key('homeRegisterButton'),
                onPressed: widget.onListBusiness,
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

class _SocialProofRail extends StatefulWidget {
  const _SocialProofRail({required this.entries});

  final List<SocialProofEntry> entries;

  @override
  State<_SocialProofRail> createState() => _SocialProofRailState();
}

class _SocialProofRailState extends State<_SocialProofRail> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _nudge(double delta) {
    if (!_scroll.hasClients) return;
    final next = (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(next, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('socialProofRail'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'SHOPS ON MERCHANTHUB',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 48, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final entry = widget.entries[i];
                    final image = entry.imageUrl;
                    return SizedBox(
                      width: 148,
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
                                      cacheWidth: (148 * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096),
                                      cacheHeight: (110 * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096),
                                      gaplessPlayback: true,
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
                Positioned(
                  left: 4,
                  child: Material(
                    color: scheme.surfaceContainerLowest,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      key: const Key('socialProofPrev'),
                      tooltip: 'Previous shops',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _nudge(-160),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  child: Material(
                    color: scheme.surfaceContainerLowest,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      key: const Key('socialProofNext'),
                      tooltip: 'Next shops',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _nudge(160),
                    ),
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

class _BrowseIndex extends StatelessWidget {
  const _BrowseIndex({
    required this.expanded,
    required this.cities,
    required this.categories,
    required this.onExpand,
    required this.onCity,
    required this.onCategory,
  });

  final _BrowseMode? expanded;
  final List<CityIndexItem> cities;
  final List<CategoryIndexItem> categories;
  final ValueChanged<_BrowseMode> onExpand;
  final ValueChanged<String> onCity;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final hasCities = cities.isNotEmpty;
    final hasCategories = categories.isNotEmpty;
    String listingWord(int n) => n == 1 ? 'listing' : 'listings';
    final categoryCount = categories.fold<int>(0, (sum, item) => sum + item.count);
    final cityCount = cities.fold<int>(0, (sum, item) => sum + item.count);

    return Column(
      key: const Key('browseIndex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              if (hasCategories)
                MhJobTile(
                  key: const Key('browseCategoryInvite'),
                  icon: Icons.category_outlined,
                  title: 'Browse by category',
                  subtitle: 'Cafés, clinics, salons — $categoryCount ${listingWord(categoryCount)}',
                  accent: MhAccent.violet,
                  onTap: () => onExpand(_BrowseMode.category),
                ),
              if (hasCategories && hasCities) const SizedBox(height: 8),
              if (hasCities)
                MhJobTile(
                  key: const Key('browseNeighborhoodInvite'),
                  icon: Icons.location_city_outlined,
                  title: 'Explore neighborhoods',
                  subtitle: 'Jump into a city — $cityCount ${listingWord(cityCount)}',
                  accent: MhAccent.mint,
                  onTap: () => onExpand(_BrowseMode.neighborhood),
                ),
            ],
          ),
        ),
        if (expanded == _BrowseMode.neighborhood && hasCities)
          _CityIndex(cities: cities, onTap: onCity)
        else if (expanded == _BrowseMode.category && hasCategories)
          _CategoryIndex(categories: categories, onTap: onCategory),
      ],
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
          Text('Neighborhoods', style: Theme.of(context).textTheme.titleMedium),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onInverseSurface),
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
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton(onPressed: onViewAll, child: const Text('See all')),
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
                          text: 'AI (suggestion): ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: business.aiMerchantSummary),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Recent reviews',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RatingStars(rating: item.review.rating, size: 16),
                        const SizedBox(width: 8),
                        Text(item.review.rating.toStringAsFixed(1)),
                      ],
                    ),
                    if (item.review.title != null && item.review.title!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.review.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(item.review.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => GoRouter.of(context).push('/businesses/${item.business.slug}'),
                        child: Text(
                          item.business.city.isEmpty
                              ? item.business.name
                              : '${item.business.name} · ${item.business.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
