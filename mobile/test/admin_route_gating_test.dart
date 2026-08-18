import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_providers.dart';
import 'package:merchanthub_mobile/features/admin/admin_repository.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/maps_config.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/merchant/dashboard_repository.dart';
import 'package:merchanthub_mobile/features/merchant/merchant_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';
import 'package:merchanthub_mobile/router.dart';

/// S-061 AC11: the new `/admin/categories` and `/admin/users` sub-routes
/// inherit the existing `/admin` role gate -- unreachable for anonymous,
/// customer, and merchant, reachable only for admin. Exercised against the
/// full app [routerProvider], the same shape as `app_shell_test.dart`'s own
/// role-gating coverage.

UserResponse _user(UserRole role) => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = role
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);

  final UserResponse? _user;

  @override
  Future<UserResponse?> build() async => _user;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async =>
      [];

  @override
  Future<List<BusinessResponse>> listMine() async => [];

  @override
  Future<List<BusinessResponse>> listByStatus(BusinessStatus status) async => [];

  @override
  Future<MapsConfig> mapsConfig() async => MapsConfig.fallback;
}

class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository() : super(ApiClient());

  @override
  Future<PlatformAnalytics> platformAnalytics() async => PlatformAnalytics((b) => b
    ..totalUsers = 0
    ..totalBusinesses = 0
    ..pendingBusinesses = 0
    ..totalReviews = 0
    ..reportedReviews = 0);

  @override
  Future<PlatformAnalyticsSeries> platformAnalyticsSeries() async => PlatformAnalyticsSeries((b) => b
    ..granularity = PlatformAnalyticsSeriesGranularityEnum.day
    ..days = 0);
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());

  @override
  Future<List<ReviewResponse>> listReported() async => [];

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async => [];
}

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(ApiClient());

  @override
  Future<List<UserResponse>> listUsers() async => [];
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(ApiClient());

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async => [];
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<ProviderContainer> _pumpAppAt(WidgetTester tester, String location, {UserResponse? user}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      adminRepositoryProvider.overrideWithValue(_FakeAdminRepository()),
      notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
      favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
    ],
  );

  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
  );
  await _pumpFrames(tester);
  router.go(location);
  await _pumpFrames(tester);
  return container;
}

void main() {
  for (final role in [UserRole.customer, UserRole.merchant]) {
    testWidgets('AC11: a signed-in ${role.name} cannot reach /admin/categories or /admin/users', (tester) async {
      final first = await _pumpAppAt(tester, '/admin/categories', user: _user(role));
      expect(find.byKey(const Key('adminCategoriesScreen')), findsNothing);
      first.dispose();

      await tester.pumpWidget(const SizedBox.shrink());
      final second = await _pumpAppAt(tester, '/admin/users', user: _user(role));
      expect(find.byKey(const Key('adminUsersScreen')), findsNothing);
      second.dispose();
    });
  }

  testWidgets('AC11: an anonymous visitor is redirected to login, not the admin sub-routes', (tester) async {
    final container = await _pumpAppAt(tester, '/admin/categories', user: null);
    expect(find.byKey(const Key('adminCategoriesScreen')), findsNothing);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    container.dispose();
  });

  testWidgets('AC11 (positive control): an admin can reach both new sub-routes', (tester) async {
    final first = await _pumpAppAt(tester, '/admin/categories', user: _user(UserRole.admin));
    expect(find.byKey(const Key('adminCategoriesScreen')), findsOneWidget);
    first.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    final second = await _pumpAppAt(tester, '/admin/users', user: _user(UserRole.admin));
    expect(find.byKey(const Key('adminUsersScreen')), findsOneWidget);
    second.dispose();
  });
}
