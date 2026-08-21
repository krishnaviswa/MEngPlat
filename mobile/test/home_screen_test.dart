import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/search_controller.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/home/home_providers.dart';
import 'package:merchanthub_mobile/features/home/home_screen.dart';
import 'package:merchanthub_mobile/features/home/social_proof_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

BusinessResponse _business({
  String id = 'biz-1',
  String slug = 'cafe-demo',
  String name = 'Cafe Demo',
  String city = 'Springfield',
  String? summary,
  int reviewCount = 2,
}) {
  return BusinessResponse((b) {
    b
      ..id = id
      ..name = name
      ..slug = slug
      ..address = '1 Main St'
      ..city = city
      ..country = 'US'
      ..status = BusinessStatus.approved
      ..averageRating = 4.5
      ..reviewCount = reviewCount
      ..aiMerchantSummary = summary;
    b.categories.add(CategoryResponse((c) => c
      ..id = 'cat-1'
      ..name = 'Cafe'
      ..slug = 'cafe'));
  });
}

ReviewResponse _review({String? summary}) {
  return ReviewResponse((b) {
    b
      ..id = 'review-1'
      ..businessId = 'biz-1'
      ..authorId = 'author-1'
      ..rating = 5
      ..title = 'Great coffee'
      ..body = 'Really enjoyed the visit, would recommend to others.'
      ..status = ReviewStatus.active
      ..likeCount = 0
      ..createdAt = DateTime.utc(2026, 1, 1);
    if (summary != null) {
      b.aiAnalysis.replace(AIAnalysisResponse((a) => a
        ..id = 'analysis-1'
        ..analysisType = 'review'
        ..provider = 'mock'
        ..summary = summary));
    }
  });
}

HomePayload _payload({
  PublicPlatformStats? stats,
  List<CityIndexItem> cities = const [],
  List<CategoryIndexItem> categories = const [],
  List<BusinessResponse> featured = const [],
  String? featuredCity,
  List<ReviewVoiceItem> voices = const [],
  String? loadError,
  List<SocialProofEntry>? socialProof,
}) {
  return HomePayload(
    socialProof: socialProof ?? kSocialProofFallback,
    heroPhotos: const [],
    stats: stats,
    cities: cities,
    categories: categories,
    featured: featured,
    featuredCity: featuredCity,
    voices: voices,
    loadError: loadError,
  );
}

PublicPlatformStats _stats() => PublicPlatformStats((b) => b
  ..totalBusinesses = 12
  ..totalReviews = 40
  ..totalCategories = 5
  ..totalCities = 3);

class _FakeSearchController extends SearchController {
  _FakeSearchController([this.catalog = const []]);

  final List<BusinessResponse> catalog;

  @override
  Future<SearchResults> build() async {
    return const SearchResults(query: SearchQuery(), items: [], page: 1, hasMore: false);
  }

  @override
  void setQueryText(String raw) {
    final q = raw.trim().toLowerCase();
    final items = q.length < 2
        ? const <BusinessResponse>[]
        : catalog.where((b) {
            final hay = '${b.name} ${b.city} ${b.categories?.map((c) => c.name).join(' ') ?? ''}'.toLowerCase();
            return hay.contains(q);
          }).toList();
    state = AsyncValue.data(SearchResults(query: SearchQuery(q: raw.trim()), items: items, page: 1, hasMore: false));
  }
}

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => null;
}

class _SignedInAuthController extends AuthController {
  _SignedInAuthController(this._user);
  final UserResponse _user;
  @override
  Future<UserResponse?> build() async => _user;
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  required HomePayload payload,
  UserResponse? user,
  List<BusinessResponse> searchCatalog = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/businesses', builder: (context, state) => Scaffold(body: Text('EXPLORE ${state.uri}'))),
      GoRoute(path: '/businesses/:slug', builder: (context, state) => Scaffold(body: Text('DETAIL ${state.pathParameters['slug']}'))),
      GoRoute(path: '/register', builder: (context, state) => const Scaffold(body: Text('REGISTER'))),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('LOGIN'))),
      GoRoute(path: '/merchant', builder: (context, state) => const Scaffold(body: Text('MERCHANT HUB'))),
      GoRoute(path: '/merchant/businesses/new', builder: (context, state) => const Scaffold(body: Text('NEW BUSINESS'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homePayloadProvider.overrideWith((ref) async => payload),
        authControllerProvider.overrideWith(
          user == null ? _FakeAuthController.new : () => _SignedInAuthController(user),
        ),
        favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
        searchControllerProvider.overrideWith(() => _FakeSearchController(searchCatalog)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('AC1/AC2: /home is a compact discovery screen', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(
        stats: _stats(),
        cities: const [CityIndexItem(name: 'Springfield', count: 2)],
        categories: [
          CategoryIndexItem(
            category: CategoryResponse((c) => c
              ..id = 'cat-1'
              ..name = 'Cafe'
              ..slug = 'cafe'),
            count: 2,
          ),
        ],
        featured: [_business()],
        featuredCity: 'Springfield',
        voices: [ReviewVoiceItem(business: _business(), review: _review())],
      ),
    );

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('searchField')), findsNothing);

    final keys = [
      'homeHero',
      'socialProofRail',
      'browseIndex',
      'featuredGrid',
      'reviewVoices',
      'trustMetrics',
    ];
    final ys = <double>[];
    for (final key in keys) {
      final box = tester.getRect(find.byKey(Key(key)));
      ys.add(box.top);
    }
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], greaterThanOrEqualTo(ys[i - 1]), reason: '${keys[i]} should be below ${keys[i - 1]}');
    }
  });

  testWidgets('AC3: hero copy, suggestion language, explore and register actions', (tester) async {
    final router = await _pumpHome(tester, payload: _payload());

    expect(find.text('Find local shops'), findsOneWidget);
    expect(find.textContaining('AI is a suggestion'), findsOneWidget);
    expect(find.byKey(const Key('homeSearchField')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('homeSearchField')), 'salon');
    await tester.tap(find.byKey(const Key('homeExploreButton')));
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE /businesses?q=salon'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('homeRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.text('REGISTER'), findsOneWidget);
  });

  testWidgets('AC4/AC5: social proof label, fallback names, no invented stats on the rail', (tester) async {
    await _pumpHome(tester, payload: _payload());

    expect(find.text('SHOPS ON MERCHANTHUB'), findsOneWidget);
    expect(find.text('Copper Kettle Cafe'), findsOneWidget);
    expect(find.byKey(const Key('socialProofPrev')), findsOneWidget);
    expect(find.byKey(const Key('socialProofNext')), findsOneWidget);
    final rail = find.byKey(const Key('socialProofRail'));
    expect(
      find.descendant(of: rail, matching: find.text('12')),
      findsNothing,
    );
    expect(
      find.descendant(of: rail, matching: find.textContaining('%')),
      findsNothing,
    );
  });

  testWidgets('AC6: long problem / how-it-works copy is omitted on mobile', (tester) async {
    await _pumpHome(tester, payload: _payload());

    expect(find.byKey(const Key('problemSection')), findsNothing);
    expect(find.byKey(const Key('howItWorks')), findsNothing);
    expect(find.byKey(const Key('merchantCta')), findsNothing);
    expect(find.text('Your reviews are scattered'), findsNothing);
  });

  testWidgets('AC7: trust metrics show live counts and hide when stats are null', (tester) async {
    await _pumpHome(tester, payload: _payload(stats: _stats()));
    expect(find.byKey(const Key('trustMetrics')), findsOneWidget);
    expect(find.text('Approved businesses'), findsOneWidget);
    expect(find.text('Active reviews'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, payload: _payload());
    expect(find.byKey(const Key('trustMetrics')), findsNothing);
  });

  testWidgets('AC8: city invite then tap opens Explore with city filter; omitted when empty', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(cities: const [CityIndexItem(name: 'Springfield', count: 2)]),
    );
    expect(find.byKey(const Key('browseNeighborhoodInvite')), findsOneWidget);
    expect(find.byKey(const Key('cityIndex')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('browseNeighborhoodInvite')));
    await tester.tap(find.byKey(const Key('browseNeighborhoodInvite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('cityIndex-Springfield')));
    await tester.tap(find.byKey(const Key('cityIndex-Springfield')));
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE /businesses?city=Springfield'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, payload: _payload());
    expect(find.byKey(const Key('cityIndex')), findsNothing);
    expect(find.byKey(const Key('browseNeighborhoodInvite')), findsNothing);
  });

  testWidgets('AC9: category invite then tap opens Explore with category filter; omitted when empty', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(
        categories: [
          CategoryIndexItem(
            category: CategoryResponse((c) => c
              ..id = 'cat-1'
              ..name = 'Cafe'
              ..slug = 'cafe'),
            count: 2,
          ),
        ],
      ),
    );
    expect(find.byKey(const Key('browseCategoryInvite')), findsOneWidget);
    expect(find.byKey(const Key('categoryIndex')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('browseCategoryInvite')));
    await tester.tap(find.byKey(const Key('browseCategoryInvite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('categoryIndex-cafe')));
    await tester.tap(find.byKey(const Key('categoryIndex-cafe')));
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE /businesses?category=cafe'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, payload: _payload());
    expect(find.byKey(const Key('categoryIndex')), findsNothing);
    expect(find.byKey(const Key('browseCategoryInvite')), findsNothing);
  });

  testWidgets('AC10: featured cards, suggestion blurb, empty state', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(
        featured: [_business(summary: 'Locals mention the patio.')],
        featuredCity: 'Springfield',
      ),
    );
    expect(find.text('Explore Springfield'), findsOneWidget);
    expect(find.text('Cafe Demo'), findsWidgets);
    expect(find.textContaining('AI (suggestion):'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, payload: _payload(loadError: 'API down'));
    expect(find.textContaining('Could not load businesses from the API'), findsOneWidget);
  });

  testWidgets('AC11: review voices with suggestion label; omitted when empty', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(
        voices: [
          ReviewVoiceItem(
            business: _business(),
            review: _review(summary: 'Customers seem happy.'),
          ),
        ],
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('reviewVoices')));
    expect(find.text('Recent reviews'), findsOneWidget);
    expect(find.textContaining('In a nutshell (suggestion):'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, payload: _payload());
    expect(find.byKey(const Key('reviewVoices')), findsNothing);
  });

  testWidgets('S-116: category/neighborhood invites hide lists until tapped', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(
        cities: const [CityIndexItem(name: 'Springfield', count: 2)],
        categories: [
          CategoryIndexItem(
            category: CategoryResponse((c) => c
              ..id = 'cat-1'
              ..name = 'Cafe'
              ..slug = 'cafe'),
            count: 2,
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('browseModeToggle')), findsNothing);
    expect(find.byKey(const Key('browseCategoryInvite')), findsOneWidget);
    expect(find.byKey(const Key('browseNeighborhoodInvite')), findsOneWidget);
    expect(find.byKey(const Key('categoryIndex')), findsNothing);
    expect(find.byKey(const Key('cityIndex')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('browseCategoryInvite')));
    await tester.tap(find.byKey(const Key('browseCategoryInvite')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categoryIndex')), findsOneWidget);
    expect(find.byKey(const Key('cityIndex')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('browseNeighborhoodInvite')));
    await tester.tap(find.byKey(const Key('browseNeighborhoodInvite')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cityIndex')), findsOneWidget);
    expect(find.byKey(const Key('categoryIndex')), findsNothing);
  });

  testWidgets('AC14: /home is reachable without a session (no login bounce in this tree)', (tester) async {
    await _pumpHome(tester, payload: _payload());
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });

  testWidgets('AC16: home renders under a dark ColorScheme without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homePayloadProvider.overrideWith((ref) async => _payload(stats: _stats())),
          authControllerProvider.overrideWith(_FakeAuthController.new),
          favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
          searchControllerProvider.overrideWith(_FakeSearchController.new),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('homeHero')), findsOneWidget);
  });

  testWidgets('signed-in merchant sees banner and Open Shop', (tester) async {
    final merchant = UserResponse((b) => b
      ..id = 'm-1'
      ..email = 'mina@example.com'
      ..fullName = 'Mina Merchant'
      ..role = UserRole.merchant
      ..isActive = true
      ..createdAt = DateTime.utc(2026, 1, 1));
    await _pumpHome(tester, payload: _payload(), user: merchant);
    expect(find.byKey(const Key('signedInBanner')), findsOneWidget);
    expect(find.textContaining('Mina Merchant'), findsOneWidget);
    expect(find.textContaining('Merchant'), findsWidgets);
    expect(find.text('Open Shop'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openHubButton')));
    await tester.pumpAndSettle();
    expect(find.text('MERCHANT HUB'), findsOneWidget);
  });

  testWidgets('List your business goes to create listing for merchants', (tester) async {
    final merchant = UserResponse((b) => b
      ..id = 'm-1'
      ..email = 'mina@example.com'
      ..fullName = 'Mina Merchant'
      ..role = UserRole.merchant
      ..isActive = true
      ..createdAt = DateTime.utc(2026, 1, 1));
    await _pumpHome(tester, payload: _payload(), user: merchant);
    await tester.tap(find.byKey(const Key('homeRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.text('NEW BUSINESS'), findsOneWidget);
  });

  testWidgets('List your business explains customer accounts cannot list', (tester) async {
    final customer = UserResponse((b) => b
      ..id = 'c-1'
      ..email = 'casey@example.com'
      ..fullName = 'Casey Customer'
      ..role = UserRole.customer
      ..isActive = true
      ..createdAt = DateTime.utc(2026, 1, 1));
    await _pumpHome(tester, payload: _payload(), user: customer);
    await tester.tap(find.byKey(const Key('homeRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listBusinessCustomerDialog')), findsOneWidget);
    expect(find.text('REGISTER'), findsNothing);
  });

  testWidgets('typing caf shows cafe suggestion overlay', (tester) async {
    await _pumpHome(
      tester,
      payload: _payload(),
      searchCatalog: [_business(name: 'Cafe Demo', slug: 'cafe-demo')],
    );
    expect(find.byKey(const Key('homeSearchSuggestions')), findsNothing);
    await tester.enterText(find.byKey(const Key('homeSearchField')), 'caf');
    await tester.pump();
    expect(find.byKey(const Key('homeSearchSuggestions')), findsOneWidget);
    expect(find.byKey(const Key('homeSearchSuggestion-cafe-demo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('homeSearchSuggestion-cafe-demo')));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL cafe-demo'), findsOneWidget);
  });
}
