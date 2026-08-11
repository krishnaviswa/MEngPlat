import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_provider.dart';
import 'favorites_providers.dart';

/// Reusable favorite icon button (filled/outline heart) reused by business
/// list rows, the business detail screen, and the Favorites screen itself.
/// Reads/writes [favoritedIdsProvider] so a toggle anywhere is reflected
/// everywhere without a re-fetch.
class FavoriteToggleButton extends ConsumerWidget {
  const FavoriteToggleButton({required this.businessId, this.onToggled, super.key});

  final String businessId;

  /// Invoked with the resulting favorited state after a successful toggle,
  /// so callers that need to react locally (e.g. the Favorites screen
  /// removing a row on un-favorite, AC8) don't have to re-derive it.
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    // Favoriting is customer-only (RBAC matrix) -- hidden outright for
    // merchant/admin sessions, but still shown to an anonymous guest so a
    // tap can route to /login (AC9).
    if (user != null && user.role != UserRole.customer) {
      return const SizedBox.shrink();
    }

    final favoritedAsync = ref.watch(favoritedIdsProvider);
    // Don't silently render empty (unfavorited) hearts forever when the
    // membership fetch failed — hide the toggle until a successful reload.
    if (favoritedAsync.hasError) {
      return const SizedBox.shrink();
    }
    final favoritedIds = favoritedAsync.valueOrNull ?? const <String>{};
    final isFavorited = favoritedIds.contains(businessId);

    return IconButton(
      key: Key('favoriteToggle-$businessId'),
      icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: isFavorited ? Colors.red : null),
      tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () => _onTap(context, ref, isLoggedIn: user != null, wasFavorited: isFavorited),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoggedIn,
    required bool wasFavorited,
  }) async {
    if (!isLoggedIn) {
      context.push('/login');
      return;
    }
    try {
      await ref.read(favoritedIdsProvider.notifier).toggle(businessId);
      onToggled?.call(!wasFavorited);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      final message = e.statusCode == 404 ? 'This business is no longer available to favorite' : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
