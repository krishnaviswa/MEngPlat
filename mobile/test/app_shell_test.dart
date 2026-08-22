import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_detail_screen.dart';
import 'package:merchanthub_mobile/features/businesses/maps_config.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/router.dart';
import 'watch_router_app.dart';

UserResponse _user(UserRole role, {String name = 'Test User'}) => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = name
  ..role = role
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _business() => BusinessResponse((b) => b
  ..id = 'biz-1'
  ..name = 'Cafe Demo'
  ..slug = 'cafe-demo'
  ..address = '1 Main St'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
  ..averageRating = 4.5
  ..reviewCount = 1);

BusinessResponse _secondBusiness() => BusinessResponse((b) => b
  ..id = 'biz-2'
  ..name = 'Bakery Demo'
  ..slug = 'bakery-demo'
  ..address = '2 Main St'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
  ..averageRating = 4.0
  ..reviewCount = 0);

BusinessResponse _pendingBusiness() => BusinessResponse((b) => b
  ..id = 'biz-3'
  ..name = 'New Shop Demo'
  ..slug = 'new-shop-demo'
  ..address = '3 Main St'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.pending
  ..averageRating = 0
  ..reviewCount = 0);

NotificationResponse _unread() => NotificationResponse((b) => b
  ..id = 'n-1'
  ..type = 'REVIEW'
  ..title = 'New review'
  ..message = 'Someone left a new review.'
  ..isRead = false
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);

  final UserResponse? _user;

  @override
  Future<UserResponse?> build() async => _user;

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({this.businesses = const []}) : super(ApiClient());

  final List<BusinessResponse> businesses;

  @override
  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async =>
      businesses;

  @override
  Future<BusinessResponse> getBySlug(String slug) async => businesses.firstWhere((b) => b.slug == slug);

  @override
  Future<List<PhotoResponse>> listPhotos(String businessId) async => [];

  @override
  Future<List<ExternalReviewResponse>> listExternalReviews(String businessId) async => [];

  @override
  Future<List<BusinessResponse>> listMine() async => businesses;

  @override
  Future<MapsConfig> mapsConfig() async => MapsConfig.fallback;

  @override
  Future<List<String>> listCities() async => [];

  @override
  Future<List<CategoryResponse>> listCategories({String? q}) async => [];

  @override
  Future<List<BusinessResponse>> listPublic({String? city, String? slugs}) async => businesses;

  @override
  Future<PublicPlatformStats?> publicStats() async => null;
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository({this.notifications = const []}) : super(ApiClient());

  final List<NotificationResponse> notifications;

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async {
    if (unreadOnly) return notifications.where((n) => !n.isRead).toList();
    return notifications;
  }
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  int listCalls = 0;

  @override
  Future<List<BusinessResponse>> listFavorites() async {
    listCalls++;
    return [];
  }
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async => [];
}

/// Pumps frames without [WidgetTester.pumpAndSettle], which never idles while
/// [UnreadCountController]'s `Timer.periodic(30s)` is armed.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required UserResponse? user,
  List<BusinessResponse> businesses = const [],
  List<NotificationResponse> notifications = const [],
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final favorites = _FakeFavoritesRepository();
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      googleSignInClientProvider.overrideWith((ref) async => const UnconfiguredGoogleSignInClient()),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository(businesses: businesses)),
      notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository(notifications: notifications)),
      favoritesRepositoryProvider.overrideWithValue(favorites),
      reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const WatchRouterApp(),
    ),
  );
  await _pumpFrames(tester);
  return container;
}

void main() {
  testWidgets('AC1: customer shell tabs are Home, Explore, Favorites, Alerts, Account', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.customer));

    expect(find.byKey(const Key('homeTab')), findsOneWidget);
    expect(find.byKey(const Key('exploreTab')), findsOneWidget);
    expect(find.byKey(const Key('favoritesTab')), findsOneWidget);
    expect(find.byKey(const Key('notificationsTab')), findsOneWidget);
    expect(find.byKey(const Key('accountTab')), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.byKey(const Key('merchantHomeTab')), findsNothing);
    expect(find.byKey(const Key('adminHomeTab')), findsNothing);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    container.dispose();
  });

  testWidgets('AC2/AC6: merchant tabs include Shop hub and land on marketing Home', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.merchant, name: 'Mina Merchant'));

    expect(find.byKey(const Key('homeTab')), findsOneWidget);
    expect(find.byKey(const Key('merchantHomeTab')), findsOneWidget);
    expect(find.byKey(const Key('exploreTab')), findsOneWidget);
    expect(find.byKey(const Key('notificationsTab')), findsOneWidget);
    expect(find.byKey(const Key('accountTab')), findsOneWidget);
    expect(find.byKey(const Key('favoritesTab')), findsNothing);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('signedInBanner')), findsOneWidget);

    container.dispose();
  });

  testWidgets('AC3/AC7: admin tabs include Hub and land on marketing Home', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.admin));

    expect(find.byKey(const Key('homeTab')), findsOneWidget);
    expect(find.byKey(const Key('adminHomeTab')), findsOneWidget);
    expect(find.byKey(const Key('favoritesTab')), findsNothing);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    container.dispose();
  });

  testWidgets('AC4/AC10: guest Explore shows Sign in only; Sign in opens login', (tester) async {
    final container = await _pumpApp(tester, user: null);

    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byKey(const Key('continueAsGuestButton')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('homeTab')), findsOneWidget);
    expect(find.byKey(const Key('exploreTab')), findsOneWidget);
    expect(find.byKey(const Key('signInTab')), findsOneWidget);
    expect(find.byKey(const Key('favoritesTab')), findsNothing);
    expect(find.byKey(const Key('notificationsTab')), findsNothing);
    expect(find.byKey(const Key('accountTab')), findsNothing);
    expect(find.byKey(const Key('logoutButton')), findsNothing);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('signInTab')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('loginMethodOtp')), findsOneWidget);
    expect(find.byKey(const Key('primaryNav')).hitTestable(), findsNothing);

    container.dispose();
  });

  testWidgets('AC5: customer session on login redirects to Home', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.customer));
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    container.dispose();
  });

  testWidgets('AC8/AC9/AC12/AC16: Account identity, Profile, logout, brand', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.customer, name: 'Casey Customer'));

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('accountIdentity')), findsOneWidget);
    expect(find.text('Casey Customer'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byKey(const Key('profileLink')), findsOneWidget);
    expect(find.byKey(const Key('brandHomeLink')), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('brandHomeLink')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('homeScreen')), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('profileLink')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('profileScreen')), findsOneWidget);
    expect(find.byKey(const Key('fullNameField')), findsOneWidget);

    container.read(routerProvider).go('/account');
    await _pumpFrames(tester);
    await container.read(authControllerProvider.notifier).logout();
    await _pumpFrames(tester);
    expect(find.byKey(const Key('continueAsGuestButton')), findsOneWidget);
    expect(find.byKey(const Key('accountIdentity')), findsNothing);

    container.dispose();
  });

  testWidgets('S-114: merchant Account shows shop, list, QR, and Grow', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.merchant, name: 'Mina Merchant'), businesses: [_business()]);

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('myShopLink')), findsOneWidget);
    expect(find.byKey(const Key('listBusinessLink')), findsOneWidget);
    expect(find.byKey(const Key('shareQrLink')), findsOneWidget);
    expect(find.byKey(const Key('growLink')), findsOneWidget);

    container.dispose();
  });

  testWidgets('S-120: Account "Share review QR" with >1 shop goes to the dashboard instead of guessing shops.first', (tester) async {
    final container = await _pumpApp(
      tester,
      user: _user(UserRole.merchant, name: 'Mina Merchant'),
      businesses: [_business(), _secondBusiness()],
    );

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('shareQrLink')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('merchantHomeScreen')), findsOneWidget);
    expect(find.byKey(const Key('shareReviewLinkQr')), findsNothing);

    container.dispose();
  });

  testWidgets('S-120: Account "Share review QR" for a single not-yet-approved shop also goes to the dashboard', (tester) async {
    final container = await _pumpApp(
      tester,
      user: _user(UserRole.merchant, name: 'Mina Merchant'),
      businesses: [_pendingBusiness()],
    );

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('shareQrLink')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('merchantHomeScreen')), findsOneWidget);
    expect(find.byKey(const Key('shareReviewLinkQr')), findsNothing);

    container.dispose();
  });

  testWidgets('AC11: unread badge shows on Notifications tab and hides at zero', (tester) async {
    final withUnread = await _pumpApp(
      tester,
      user: _user(UserRole.customer),
      notifications: [_unread()],
    );
    expect(find.byKey(const Key('notificationBadge')), findsOneWidget);
    withUnread.dispose();

    await tester.pumpWidget(const SizedBox.shrink());

    final none = await _pumpApp(tester, user: _user(UserRole.customer));
    expect(find.byKey(const Key('notificationBadge')), findsNothing);
    none.dispose();
  });

  testWidgets('AC13: login and business detail have no bottom nav', (tester) async {
    final container = await _pumpApp(tester, user: null, businesses: [_business()]);
    expect(find.byKey(const Key('primaryNav')), findsNothing);

    await tester.tap(find.byKey(const Key('continueAsGuestButton')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('primaryNav')), findsOneWidget);

    container.read(routerProvider).push('/businesses/cafe-demo');
    await _pumpFrames(tester);
    expect(find.byType(BusinessDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('primaryNav')).hitTestable(), findsNothing);

    container.dispose();
  });

  testWidgets('S-103: guest Explore does not fetch Favorites', (tester) async {
    final container = await _pumpApp(tester, user: null);
    await tester.tap(find.byKey(const Key('continueAsGuestButton')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('exploreTab')));
    await _pumpFrames(tester);

    final favorites = container.read(favoritesRepositoryProvider) as _FakeFavoritesRepository;
    expect(favorites.listCalls, 0);
    expect(find.text('Businesses'), findsOneWidget);
    container.dispose();
  });

  testWidgets('S-103: Account profile stack is kept when switching tabs', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.customer, name: 'Casey Customer'));

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('profileLink')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('profileScreen')).hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const Key('exploreTab')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('profileScreen')).hitTestable(), findsNothing);

    await tester.tap(find.byKey(const Key('accountTab')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('profileScreen')).hitTestable(), findsOneWidget);

    container.dispose();
  });

  testWidgets('S-116: system back on Shop hub goes Home instead of leaving', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.merchant, name: 'Mina Merchant'));

    container.read(routerProvider).go('/merchant');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('merchantHomeScreen')).hitTestable(), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpFrames(tester);
    expect(find.byKey(const Key('homeScreen')).hitTestable(), findsAtLeastNWidgets(1));

    container.dispose();
  });

  testWidgets('S-116: system back on Shop nested route pops to hub first', (tester) async {
    final container = await _pumpApp(tester, user: _user(UserRole.merchant, name: 'Mina Merchant'));

    container.read(routerProvider).go('/merchant');
    await _pumpFrames(tester);
    container.read(routerProvider).push('/merchant/insights');
    await _pumpFrames(tester);
    expect(find.text('Insights'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpFrames(tester);
    expect(find.text('Merchant'), findsOneWidget);
    expect(find.byKey(const Key('homeScreen')).hitTestable(), findsNothing);

    container.dispose();
  });
}
