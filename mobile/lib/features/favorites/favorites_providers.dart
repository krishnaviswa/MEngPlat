import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(apiClientProvider)),
);

/// Single shared source of truth for favorite *membership*, consumed by
/// every favorite toggle in the app (business list rows, the business detail
/// screen, and the Favorites screen itself) -- deliberately **not**
/// `.autoDispose` so a toggle on one screen is reflected instantly on
/// another without each one re-fetching `GET /favorites` (Architect spec,
/// S-024 "Cache / side effects"). Rebuilds automatically on login/logout
/// since it watches `authControllerProvider`.
class FavoritedIdsController extends AsyncNotifier<Set<String>> {
  @override
  FutureOr<Set<String>> build() async {
    // Awaiting the *future* (rather than peeking `.valueOrNull`) lets this
    // build suspend until auth actually settles instead of racing a
    // still-loading authControllerProvider, completing early with a stale
    // {} and then getting silently superseded by a second build once auth
    // resolves -- which left the .future accessor's Completer from the
    // first (discarded) build generation unresolved.
    final user = await ref.watch(authControllerProvider.future);
    if (user?.role != UserRole.customer) return const <String>{};
    final favorites = await ref.watch(favoritesRepositoryProvider).listFavorites();
    return favorites.map((business) => business.id).toSet();
  }

  /// Optimistically flips [businessId]'s membership (AC1/2), calls
  /// `POST`/`DELETE /favorites` in the background, and reverts + rethrows on
  /// failure so the caller can surface a non-blocking error (AC3).
  Future<void> toggle(String businessId) async {
    final previous = state.valueOrNull ?? const <String>{};
    final wasFavorited = previous.contains(businessId);
    final optimistic = {...previous};
    if (wasFavorited) {
      optimistic.remove(businessId);
    } else {
      optimistic.add(businessId);
    }
    state = AsyncValue.data(optimistic);

    final repository = ref.read(favoritesRepositoryProvider);
    try {
      if (wasFavorited) {
        await repository.removeFavorite(businessId);
      } else {
        await repository.addFavorite(businessId);
      }
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}

final favoritedIdsProvider = AsyncNotifierProvider<FavoritedIdsController, Set<String>>(
  FavoritedIdsController.new,
);

/// The Favorites screen's list *content* (name/city/rating, not just
/// membership) -- separate from [favoritedIdsProvider] per the Architect
/// spec.
final favoritesListProvider = FutureProvider.autoDispose<List<BusinessResponse>>((ref) {
  return ref.watch(favoritesRepositoryProvider).listFavorites();
});
