import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'business_repository.dart';
import 'maps_config.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);

final businessListProvider = FutureProvider.autoDispose<List<BusinessResponse>>((ref) {
  return ref.watch(businessRepositoryProvider).searchBusinesses();
});

final searchFacetsProvider = FutureProvider.autoDispose<(List<String>, List<CategoryResponse>)>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final cities = await repo.listCities();
  final categories = await repo.listCategories();
  return (cities, categories);
});

final mapsConfigProvider = FutureProvider<MapsConfig>((ref) {
  return ref.watch(businessRepositoryProvider).mapsConfig();
});

final businessPhotosProvider = FutureProvider.autoDispose.family<List<PhotoResponse>, String>((ref, businessId) {
  return ref.watch(businessRepositoryProvider).listPhotos(businessId);
});

/// Backs the S-023 business detail screen (`/businesses/:slug`), a public
/// route reachable while logged out (see ADR-003).
final businessDetailProvider = FutureProvider.autoDispose.family<BusinessResponse, String>((ref, slug) {
  return ref.watch(businessRepositoryProvider).getBySlug(slug);
});

/// Collect/QR landing (`/collect/:slug`) — UUID or slug, matching web.
final collectBusinessProvider = FutureProvider.autoDispose.family<BusinessResponse, String>((ref, param) {
  return ref.watch(businessRepositoryProvider).resolveCollectTarget(param);
});

final externalReviewsProvider = FutureProvider.autoDispose.family<List<ExternalReviewResponse>, String>((ref, businessId) {
  return ref.watch(businessRepositoryProvider).listExternalReviews(businessId);
});

/// IDs of businesses owned by the current user, empty for non-merchants (or
/// while logged out). Used client-side to hide "Add review" on a merchant's
/// own business (S-023 AC12) -- not a new endpoint, just `GET /businesses/mine`
/// reused for a client-only check.
final myBusinessIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  // Await the *future* (not `.valueOrNull`) so this suspends until auth
  // actually settles instead of racing a still-loading authControllerProvider
  // -- same fix as FavoritedIdsController.build() in favorites_providers.dart.
  final user = await ref.watch(authControllerProvider.future);
  if (user?.role != UserRole.merchant) return {};
  final mine = await ref.watch(businessRepositoryProvider).listMine();
  return mine.map((business) => business.id).toSet();
});
