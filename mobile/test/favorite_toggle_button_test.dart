import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/favorites/favorite_toggle_button.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';

/// S-024 AC1/AC2/AC3/AC9/AC11: the shared favorite toggle icon flips
/// optimistically, rolls back with a snackbar on failure, routes a
/// logged-out tap to `/login`, and surfaces a clear message on a stale 404.

UserResponse _customer() => UserResponse((b) => b
  ..id = 'customer-1'
  ..email = 'customer@example.com'
  ..fullName = 'Test Customer'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository({this.addError, this.removeError}) : super(ApiClient());

  final Object? addError;
  final Object? removeError;

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];

  @override
  Future<void> addFavorite(String businessId) async {
    final error = addError;
    if (error != null) throw error;
  }

  @override
  Future<void> removeFavorite(String businessId) async {
    final error = removeError;
    if (error != null) throw error;
  }
}

Future<ProviderContainer> _pumpToggle(
  WidgetTester tester, {
  required UserResponse? user,
  Object? addError,
  Object? removeError,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      favoritesRepositoryProvider.overrideWithValue(
        _FakeFavoritesRepository(addError: addError, removeError: removeError),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (context, state) =>
            const Scaffold(body: Center(child: FavoriteToggleButton(businessId: 'biz-1'))),
      ),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('LOGIN_SCREEN'))),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
  await tester.pumpAndSettle();
  return container;
}

Finder _toggleFinder() => find.byKey(const Key('favoriteToggle-biz-1'));

void main() {
  testWidgets('AC1/AC2: tapping the toggle flips it favorited then back to unfavorited', (tester) async {
    await _pumpToggle(tester, user: _customer());

    Icon icon() => tester.widget<Icon>(find.descendant(of: _toggleFinder(), matching: find.byType(Icon)));
    expect(icon().icon, Icons.favorite_border);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();
    expect(icon().icon, Icons.favorite);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();
    expect(icon().icon, Icons.favorite_border);
  });

  testWidgets('AC3: a failed toggle rolls back the icon and shows a snackbar', (tester) async {
    await _pumpToggle(tester, user: _customer(), addError: ApiException('Could not save favorite'));

    Icon icon() => tester.widget<Icon>(find.descendant(of: _toggleFinder(), matching: find.byType(Icon)));
    expect(icon().icon, Icons.favorite_border);

    await tester.tap(_toggleFinder());
    await tester.pump();
    await tester.pump();

    expect(icon().icon, Icons.favorite_border, reason: 'must roll back to unfavorited on failure');
    expect(find.text('Could not save favorite'), findsOneWidget);
  });

  testWidgets('AC9: tapping the toggle while logged out routes to /login instead of favoriting', (tester) async {
    await _pumpToggle(tester, user: null);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);
  });

  testWidgets('AC11: a stale-business 404 surfaces a clear message, not a generic error', (tester) async {
    await _pumpToggle(tester, user: _customer(), addError: ApiException('Business not found or not approved', statusCode: 404));

    await tester.tap(_toggleFinder());
    await tester.pump();
    await tester.pump();

    expect(find.text('This business is no longer available to favorite'), findsOneWidget);
  });
}
