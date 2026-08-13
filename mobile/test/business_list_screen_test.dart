import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_screen.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/location_service.dart';
import 'package:merchanthub_mobile/features/businesses/maps_config.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';

UserResponse _user() => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _business({
  String id = 'biz-1',
  String slug = 'cafe-demo',
  String name = 'Cafe Demo',
  String? storefront,
  num? lat,
  num? lng,
}) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = name
    ..slug = slug
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..country = 'US'
    ..status = BusinessStatus.approved
    ..averageRating = 4.5
    ..reviewCount = 2
    ..storefrontUrl = storefront
    ..latitude = lat
    ..longitude = lng);
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({
    this.businesses = const [],
    this.searchError,
  }) : super(ApiClient()) {
    cities = ['Springfield', 'Chennai'];
    categories = [
      CategoryResponse((b) => b
        ..id = 'cat-1'
        ..name = 'Cafe'
        ..slug = 'cafe'),
    ];
  }

  List<BusinessResponse> businesses;
  List<String> cities = const [];
  List<CategoryResponse> categories = const [];
  Object? searchError;
  SearchQuery? lastQuery;
  final pages = <int>[];

  @override
  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async {
    lastQuery = query;
    pages.add(page);
    final error = searchError;
    if (error != null) throw error;
    return businesses;
  }

  @override
  Future<List<String>> listCities() async => cities;

  @override
  Future<List<CategoryResponse>> listCategories() async => categories;

  @override
  Future<MapsConfig> mapsConfig() async => MapsConfig.fallback;

  @override
  Future<List<PhotoResponse>> listPhotos(String businessId) async => [];
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.point);

  final GeoPoint? point;

  @override
  Future<GeoPoint?> currentPosition() async => point;
}

Future<_FakeBusinessRepository> _pumpExplore(
  WidgetTester tester, {
  UserResponse? user,
  List<BusinessResponse> businesses = const [],
  Object? searchError,
  GeoPoint? location,
  bool withRouter = false,
}) async {
  final repo = _FakeBusinessRepository(businesses: businesses, searchError: searchError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(repo),
      favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
      locationServiceProvider.overrideWithValue(_FakeLocationService(location)),
    ],
  );
  addTearDown(container.dispose);

  if (withRouter) {
    final router = GoRouter(
      initialLocation: '/businesses',
      routes: [
        GoRoute(
          path: '/businesses',
          builder: (context, state) => const BusinessListScreen(),
          routes: [
            GoRoute(
              path: ':slug',
              builder: (context, state) => Scaffold(body: Text('DETAIL_${state.pathParameters['slug']}')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
  } else {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessListScreen()),
      ),
    );
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return repo;
}

void main() {
  testWidgets('Explore app bar has no logout, favorites, or notifications actions', (tester) async {
    await _pumpExplore(tester, user: _user());
    expect(find.byKey(const Key('logoutButton')), findsNothing);
    expect(find.byKey(const Key('favoritesButton')), findsNothing);
    expect(find.byKey(const Key('notificationsButton')), findsNothing);
    expect(find.byKey(const Key('signInButton')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpExplore(tester, user: null);
    expect(find.byKey(const Key('logoutButton')), findsNothing);
    expect(find.byKey(const Key('signInButton')), findsNothing);
  });

  testWidgets('AC12: guest Explore shows search chrome', (tester) async {
    await _pumpExplore(tester, user: null);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.byKey(const Key('filtersButton')), findsOneWidget);
    expect(find.byKey(const Key('useLocationButton')), findsOneWidget);
    expect(find.byKey(const Key('mapToggle')), findsOneWidget);
    expect(find.text('Businesses'), findsOneWidget);
  });

  testWidgets('AC1: typing a query sends q after debounce', (tester) async {
    final repo = await _pumpExplore(tester, user: _user());
    await tester.enterText(find.byKey(const Key('searchField')), 'chrompet');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(repo.lastQuery?.q, 'chrompet');
  });

  testWidgets('AC19: search error shows Retry', (tester) async {
    await _pumpExplore(tester, user: _user(), searchError: ApiException('Network error'));
    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('AC20: empty results message', (tester) async {
    await _pumpExplore(tester, user: _user(), businesses: const []);
    expect(find.text('No businesses found'), findsOneWidget);
  });

  testWidgets('AC4/AC3: filters sheet lists live cities and applies city', (tester) async {
    final repo = await _pumpExplore(tester, user: _user(), businesses: [_business()]);
    await tester.tap(find.byKey(const Key('filtersButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filtersSheet')), findsOneWidget);
    expect(find.text('Chennai'), findsWidgets);
    expect(find.text('Cafe'), findsWidgets);

    await tester.tap(find.byKey(const Key('cityFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chennai').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('applyFiltersButton')));
    await tester.pumpAndSettle();
    expect(repo.lastQuery?.city, 'Chennai');
  });

  testWidgets('AC5: Use my location sends lat/lng/radius', (tester) async {
    final repo = await _pumpExplore(
      tester,
      user: _user(),
      location: const GeoPoint(13.08, 80.27),
    );
    await tester.tap(find.byKey(const Key('useLocationButton')));
    await tester.pumpAndSettle();
    expect(repo.lastQuery?.lat, closeTo(13.08, 0.001));
    expect(repo.lastQuery?.lng, closeTo(80.27, 0.001));
    expect(repo.lastQuery?.radiusKm, 10);
  });

  testWidgets('AC6: location failure shows a message and does not geo-filter', (tester) async {
    final repo = await _pumpExplore(tester, user: _user());
    final before = repo.lastQuery;
    await tester.tap(find.byKey(const Key('useLocationButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('locationErrorSnackBar')), findsOneWidget);
    expect(repo.lastQuery?.hasLocation, isFalse);
    expect(repo.lastQuery?.lat, before?.lat);
  });

  testWidgets('AC8/AC9: map toggle shows OSM pins and pin opens detail', (tester) async {
    await _pumpExplore(
      tester,
      user: _user(),
      businesses: [_business(lat: 13.08, lng: 80.27)],
      withRouter: true,
    );
    await tester.tap(find.byKey(const Key('mapToggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('resultsMap')), findsOneWidget);
    expect(find.byKey(const Key('mapPin_cafe-demo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mapPin_cafe-demo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('DETAIL_cafe-demo'), findsOneWidget);
  });
}
