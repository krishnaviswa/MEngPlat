import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/widgets.dart';
import '../businesses/business_card.dart';
import 'favorites_providers.dart';

/// Dedicated Favorites list screen (own top-level entry point -- mobile has
/// no `/profile` page to nest it under yet). List content comes from
/// [favoritesListProvider]; un-favoriting a row removes it from view
/// immediately (AC8) via local state, since [favoritesListProvider] itself
/// isn't re-fetched on every toggle. Rows reuse [BusinessCard] so the list
/// stays visually consistent with `BusinessListScreen` (Architect spec).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final Set<String> _locallyRemoved = {};

  Future<void> _refresh() {
    // `.then` (rather than a bare `await` statement) so the refreshed
    // value counts as "used" -- ref.refresh is @useResult in riverpod.
    return ref.refresh(favoritesListProvider.future).then((_) {
      if (mounted) setState(_locallyRemoved.clear);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: favoritesAsync.when(
          loading: () => const _CenteredScroll(child: MhSkeleton()),
          error: (error, _) => _CenteredScroll(
            child: MhError(error: error, onRetry: () => ref.invalidate(favoritesListProvider)),
          ),
          data: (favorites) {
            final visible = favorites.where((business) => !_locallyRemoved.contains(business.id)).toList();
            if (visible.isEmpty) {
              return _CenteredScroll(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No favorites yet — explore businesses to save your favorites'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/businesses'),
                      child: const Text('Browse businesses'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final business = visible[index];
                return BusinessCard(
                  business: business,
                  onTap: () => context.push('/businesses/${business.slug}'),
                  onFavoriteToggled: (favorited) {
                    if (!favorited) setState(() => _locallyRemoved.add(business.id));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
