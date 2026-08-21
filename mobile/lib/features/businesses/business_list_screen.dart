import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../ui/widgets.dart';
import '../theme/theme_toggle_button.dart';
import 'business_card.dart';
import 'business_list_provider.dart';
import 'location_service.dart';
import 'maps_config.dart';
import 'osm_map_view.dart';
import 'search_controller.dart';
import 'search_filter_sheet.dart';
import 'search_query.dart';

class BusinessListScreen extends ConsumerStatefulWidget {
  const BusinessListScreen({super.key});

  @override
  ConsumerState<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends ConsumerState<BusinessListScreen> {
  var _showMap = false;

  @override
  void initState() {
    super.initState();
    // AC 6 (S-061/M-63): a category chip tapped from the admin category list
    // or a business's detail screen lands here pre-filtered via
    // `?category=`. go_router already passes query params through with no
    // route-pattern change; only the "apply it on first frame" wiring was
    // missing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // GoRouterState.of throws when this screen is hosted outside a
      // GoRouter route tree (e.g. some widget tests mount it directly under
      // MaterialApp) -- guard so that stays a no-op instead of a crash; in
      // the real app it is always reached as a GoRoute builder.
      String? category;
      String? city;
      String? q;
      try {
        final params = GoRouterState.of(context).uri.queryParameters;
        category = params['category'];
        city = params['city'];
        q = params['q'];
      } on GoError {
        category = null;
        city = null;
        q = null;
      }
      if (category != null || city != null || q != null) {
        ref.read(searchControllerProvider.notifier).applyQuery(
              SearchQuery(category: category, city: city, q: q),
            );
      }
    });
  }

  Future<void> _openFilters(SearchQuery query) async {
    final facets = await ref.read(searchFacetsProvider.future);
    if (!mounted) return;
    final next = await showSearchFilterSheet(
      context: context,
      query: query,
      cities: facets.$1,
      categories: facets.$2,
    );
    if (next == null || !mounted) return;
    await ref.read(searchControllerProvider.notifier).applyQuery(next);
  }

  Future<void> _useLocation(SearchQuery query) async {
    final point = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(key: Key('locationErrorSnackBar'), content: Text('Could not get your location. Check permissions.')),
      );
      return;
    }
    await ref.read(searchControllerProvider.notifier).applyQuery(
          query.copyWith(lat: point.latitude, lng: point.longitude),
        );
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchControllerProvider);
    final query = search.valueOrNull?.query ?? const SearchQuery();

    return Scaffold(
      appBar: AppBar(title: const Text('Businesses'), actions: const [ThemeToggleButton()]),
      body: Column(
        children: [
          const _ExploreSearchHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('filtersButton'),
                  onPressed: () => _openFilters(query),
                  icon: const Icon(Icons.tune),
                  label: const Text('Filters'),
                ),
                TextButton.icon(
                  key: const Key('useLocationButton'),
                  onPressed: () => _useLocation(query),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my location'),
                ),
                TextButton.icon(
                  key: const Key('mapToggle'),
                  onPressed: () => setState(() => _showMap = !_showMap),
                  icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
                  label: Text(_showMap ? 'List' : 'Map'),
                ),
              ],
            ),
          ),
          if (query.hasLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Near ${query.lat!.toStringAsFixed(4)}, ${query.lng!.toStringAsFixed(4)} (${query.radiusKm.toStringAsFixed(0)} km)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            key: const Key('featuredDisclaimerText'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Featured = paid boost, not a quality score.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(searchControllerProvider.notifier).reload(),
              child: search.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [MhSkeleton()],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  MhError(error: error, onRetry: () => ref.invalidate(searchControllerProvider)),
                ],
              ),
              data: (results) {
                if (results.items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No businesses found')),
                    ],
                  );
                }
                if (_showMap) {
                  return _ResultsMap(results: results);
                }
                return _ResultsList(results: results);
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same two paddings as before (S-117): typing rebuilds only this subtree.
class _ExploreSearchHeader extends ConsumerStatefulWidget {
  const _ExploreSearchHeader();

  @override
  ConsumerState<_ExploreSearchHeader> createState() => _ExploreSearchHeaderState();
}

class _ExploreSearchHeaderState extends ConsumerState<_ExploreSearchHeader> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typed = _searchController.text.trim();
    final catalog = ref.watch(searchControllerProvider).valueOrNull?.items ?? const <BusinessResponse>[];
    final suggestions = typed.length >= 2
        ? catalog.where((b) => b.name.toLowerCase().contains(typed.toLowerCase())).take(6).toList()
        : const <BusinessResponse>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            key: const Key('searchField'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search businesses',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {});
              ref.read(searchControllerProvider.notifier).setQueryText(value);
            },
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              key: const Key('searchSuggestions'),
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  for (final business in suggestions)
                    ListTile(
                      key: Key('searchSuggestion-${business.slug}'),
                      dense: true,
                      title: Text(business.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        business.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => context.push('/businesses/${business.slug}'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = results.isLoadingMore ? 1 : 0;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 240) {
          ref.read(searchControllerProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: results.items.length + extra,
        itemBuilder: (context, index) {
          if (index >= results.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(key: Key('loadMoreIndicator'))),
            );
          }
          final business = results.items[index];
          return BusinessCard(
            business: business,
            onTap: () => context.push('/businesses/${business.slug}'),
          );
        },
      ),
    );
  }
}

class _ResultsMap extends ConsumerWidget {
  const _ResultsMap({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = markersForBusinesses(results.items);
    if (markers.isEmpty) {
      return const Center(child: Text('No mapped locations in these results'));
    }
    final config = ref.watch(mapsConfigProvider).valueOrNull ?? MapsConfig.fallback;
    final query = results.query;
    final center = query.hasLocation ? LatLng(query.lat!, query.lng!) : null;
    return OsmMapView(
      mapKey: const Key('resultsMap'),
      markers: markers,
      config: config,
      center: center,
      zoom: query.hasLocation ? 12 : 11,
      height: double.infinity,
      onMarkerTap: (marker) => context.push('/businesses/${marker.slug}'),
    );
  }
}
