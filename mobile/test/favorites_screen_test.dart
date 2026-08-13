import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_screen.dart';

/// S-024 AC4/AC5/AC7/AC8: the Favorites screen's list rendering, empty
/// state, error+Retry, and immediate (optimistic) row removal on un-favorite.

UserResponse _customer() => UserResponse((b) => b
  ..id = 'customer-1'
  ..email = 'customer@example.com'
  ..fullName = 'Test Customer'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _business(String id, String name) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = name
    ..slug = id
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..state = 'IL'
    ..country = 'US'
    ..status = BusinessStatus.approved
    ..averageRating = 4.5
    ..reviewCount = 2);
}

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _customer();
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository({this.favorites = const [], this.listError}) : super(ApiClient());

  final List<BusinessResponse> favorites;
  final Object? listError;

  @override
  Future<List<BusinessResponse>> listFavorites() async {
    listCalls++;
    final error = listError;
    if (error != null) throw error;
    return favorites;
  }

  @override
  Future<void> removeFavorite(String businessId) async {}

  int listCalls = 0;
}

Future<_FakeFavoritesRepository> _pumpFavoritesScreen(
  WidgetTester tester, {
  List<BusinessResponse> favorites = const [],
  Object? listError,
}) async {
  final favoritesRepository = _FakeFavoritesRepository(favorites: favorites, listError: listError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      favoritesRepositoryProvider.overrideWithValue(favoritesRepository),
    ],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/businesses', builder: (context, state) => const Scaffold(body: Text('BUSINESS_LIST'))),
      GoRoute(
        path: '/businesses/:slug',
        builder: (context, state) => const Scaffold(body: Text('BUSINESS_DETAIL')),
      ),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
  await tester.pumpAndSettle();
  return favoritesRepository;
}

void main() {
  testWidgets('AC4: lists favorited businesses with name, city/state and rating', (tester) async {
    await _pumpFavoritesScreen(tester, favorites: [_business('biz-1', 'Coffee Corner')]);

    expect(find.text('Coffee Corner'), findsOneWidget);
    expect(find.text('Springfield, IL'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('AC5: shows an empty-state message with a way back to the business list', (tester) async {
    await _pumpFavoritesScreen(tester, favorites: const []);

    expect(find.textContaining('No favorites yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Browse businesses'));
    await tester.pumpAndSettle();

    expect(find.text('BUSINESS_LIST'), findsOneWidget);
  });

  testWidgets('AC7: shows an inline error with a Retry action when the initial load fails', (tester) async {
    await _pumpFavoritesScreen(tester, listError: ApiException('Network error'));

    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('AC8: un-favoriting a row removes it from the list immediately', (tester) async {
    await _pumpFavoritesScreen(
      tester,
      favorites: [_business('biz-1', 'Coffee Corner'), _business('biz-2', 'Book Nook')],
    );

    expect(find.text('Coffee Corner'), findsOneWidget);
    expect(find.text('Book Nook'), findsOneWidget);

    await tester.tap(find.byKey(const Key('favoriteToggle-biz-1')));
    await tester.pumpAndSettle();

    expect(find.text('Coffee Corner'), findsNothing, reason: 'un-favorited row must disappear without a manual refresh');
    expect(find.text('Book Nook'), findsOneWidget);
  });

  testWidgets('AC6: pull-to-refresh re-fetches the favorites list', (tester) async {
    final favoritesRepository = await _pumpFavoritesScreen(tester, favorites: [_business('biz-1', 'Coffee Corner')]);
    final callsAfterInitialLoad = favoritesRepository.listCalls;
    expect(callsAfterInitialLoad, greaterThan(0));

    // Invoke the RefreshIndicator's onRefresh callback directly rather than
    // via RefreshIndicatorState.show()/a drag gesture: the latter drives a
    // real AnimationController that can hang a widget test indefinitely if
    // awaited without precisely-interleaved pump() calls.
    final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();
    await tester.pump();

    expect(
      favoritesRepository.listCalls,
      greaterThan(callsAfterInitialLoad),
      reason: 'pull-to-refresh must trigger a refetch of the favorites list',
    );
  });
}
