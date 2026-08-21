import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/reviews/collect_review_screen.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

/// S-059 (M-71 parity) AC 2-5: the public, ungated review-collection landing
/// screen -- no star-rating interception (AC2), authenticated submission via
/// the existing createReview path (AC3), unauthenticated submit redirects to
/// `/login?next=/collect/{slug}` (AC4), optional non-gating Google review
/// suggestion after success (AC5).

BusinessResponse _business({
  String id = 'biz-1',
  String slug = 'joes-diner',
  String name = "Joe's Diner",
  BusinessStatus status = BusinessStatus.approved,
}) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = name
    ..slug = slug
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..country = 'US'
    ..status = status
    ..averageRating = 4.5
    ..reviewCount = 2);
}

UserResponse _user({String id = 'cust-1', UserRole role = UserRole.customer}) {
  return UserResponse((b) => b
    ..id = id
    ..email = '$id@example.com'
    ..fullName = 'Test User'
    ..role = role
    ..isActive = true
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({this.business, this.error}) : super(ApiClient());

  final BusinessResponse? business;
  final Object? error;
  final List<String> slugLookups = [];
  final List<String> idLookups = [];

  @override
  Future<BusinessResponse> getBySlug(String slug) async {
    slugLookups.add(slug);
    final err = error;
    if (err != null) throw err;
    return business ?? _business();
  }

  @override
  Future<BusinessResponse> getById(String businessId) async {
    idLookups.add(businessId);
    final err = error;
    if (err != null) throw err;
    return business ?? _business();
  }
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.createError}) : super(ApiClient());

  final Object? createError;
  int createCalls = 0;
  int? lastRating;
  String? lastBody;

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async => [];

  @override
  Future<ReviewResponse> createReview({
    required String businessId,
    required int rating,
    String? title,
    required String body,
  }) async {
    createCalls++;
    lastRating = rating;
    lastBody = body;
    final err = createError;
    if (err != null) throw err;
    return ReviewResponse((b) => b
      ..id = 'new-review'
      ..businessId = businessId
      ..authorId = 'cust-1'
      ..rating = rating
      ..body = body
      ..status = ReviewStatus.active
      ..likeCount = 0
      ..createdAt = DateTime.utc(2026, 1, 1));
  }
}

class _PumpResult {
  _PumpResult(this.reviews, this.businesses);

  final _FakeReviewRepository reviews;
  final _FakeBusinessRepository businesses;
}

Future<_PumpResult> _pumpCollectScreen(
  WidgetTester tester, {
  required UserResponse? user,
  BusinessResponse? business,
  Object? businessError,
  Object? createError,
  String location = '/collect/joes-diner',
}) async {
  final reviewRepository = _FakeReviewRepository(createError: createError);
  final businessRepository = _FakeBusinessRepository(business: business, error: businessError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(businessRepository),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/collect/:slug',
        builder: (context, state) => CollectReviewScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => Scaffold(body: Text('LOGIN next=${state.uri.queryParameters['next']}'))),
    ],
  );

  // Widen the test surface -- the default 800x600 surface is too short to
  // fit the full form (rating + error slot + body field + submit button)
  // without a scroll, which makes `tap()` silently miss an off-screen
  // submit button rather than fail loudly. Same fix S-058's Tester applied
  // to business_detail_screen_test.dart for its own SliverList.
  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Warm authControllerProvider before pumping -- the real app always has a
  // live listener on it (router.dart's _AuthRefreshNotifier, wired app-wide
  // at startup), so by the time anyone reaches /collect/:slug it has already
  // resolved. CollectReviewScreen itself only *reads* (not *watches*) auth
  // state, inside _submit -- deliberately, since AC2 requires the landing
  // view to render with zero dependency on auth having settled. Without this
  // warm-up the provider would still be AsyncLoading at the first ref.read
  // in this test's synchronous tap, which is a test-harness gap, not a
  // production one.
  await container.read(authControllerProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _PumpResult(reviewRepository, businessRepository);
}

void main() {
  testWidgets('AC2: shows business name and a 1-5 star control reachable without a session', (tester) async {
    await _pumpCollectScreen(tester, user: null, business: _business(name: "Joe's Diner"));

    expect(find.byKey(const Key('collectReviewScreen')), findsOneWidget);
    expect(find.text("Joe's Diner"), findsOneWidget);
    for (var i = 1; i <= 5; i++) {
      expect(find.byKey(Key('ratingStar$i')), findsOneWidget);
    }
    // The body field is present regardless of which star is picked -- no
    // rating-value branch/intercept (AC2).
    expect(find.byKey(const Key('collectReviewBodyField')), findsOneWidget);
  });

  testWidgets('AC2: a 1-star and a 5-star pick both continue through the identical next step', (tester) async {
    await _pumpCollectScreen(tester, user: null, business: _business());

    await tester.tap(find.byKey(const Key('ratingStar1')));
    await tester.pump();
    expect(find.byKey(const Key('collectReviewBodyField')), findsOneWidget);
    expect(find.byKey(const Key('collectReviewNotFound')), findsNothing);

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.pump();
    expect(find.byKey(const Key('collectReviewBodyField')), findsOneWidget);
    expect(find.byKey(const Key('collectReviewNotFound')), findsNothing);
  });

  testWidgets('a suspended/pending business shows the not-available empty state, not a crash', (tester) async {
    await _pumpCollectScreen(tester, user: null, business: _business(status: BusinessStatus.suspended));

    expect(find.byKey(const Key('collectReviewNotFound')), findsOneWidget);
    expect(find.byKey(const Key('collectReviewBodyField')), findsNothing);
  });

  testWidgets('AC3: a signed-in customer submitting rating + 10+ char body creates the review', (tester) async {
    final repository = await _pumpCollectScreen(
      tester,
      user: _user(),
      business: _business(id: 'biz-1'),
    );

    await tester.tap(find.byKey(const Key('ratingStar4')));
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Great walk-in service today.');
    await tester.pump();

    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.reviews.createCalls, 1);
    expect(repository.reviews.lastRating, 4);
    expect(repository.reviews.lastBody, 'Great walk-in service today.');
    expect(find.byKey(const Key('collectReviewSuccess')), findsOneWidget);
  });

  testWidgets('AC4: submitting while signed out redirects to /login?next=/collect/{slug}, no silent failure', (
    tester,
  ) async {
    final repository = await _pumpCollectScreen(
      tester,
      user: null,
      business: _business(slug: 'joes-diner'),
    );

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Great walk-in service today.');
    await tester.pump();

    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.reviews.createCalls, 0, reason: 'no review should be created for an unauthenticated attempt');
    expect(find.text('LOGIN next=/collect/joes-diner'), findsOneWidget);
  });

  testWidgets('AC5: after a successful submit, an optional "leave a Google review" affordance is offered', (
    tester,
  ) async {
    await _pumpCollectScreen(tester, user: _user(), business: _business());

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Great walk-in service today.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('collectReviewSuccess')), findsOneWidget);
    final suggestButton = tester.widget<OutlinedButton>(find.byKey(const Key('suggestGoogleReviewButton')));
    // Optional, not required to complete the flow -- the flow has already
    // completed (success state shown above) whether or not this is tapped.
    expect(suggestButton.onPressed, isNotNull);
  });

  testWidgets('S-118 AC3: a UUID collect path loads the shop via getById, not slug', (tester) async {
    const uuid = '550e8400-e29b-41d4-a716-446655440000';
    final pumped = await _pumpCollectScreen(
      tester,
      user: null,
      business: _business(id: uuid, name: "Joe's Diner"),
      location: '/collect/$uuid',
    );

    expect(find.text("Joe's Diner"), findsOneWidget);
    expect(pumped.businesses.idLookups, [uuid]);
    expect(pumped.businesses.slugLookups, isEmpty);
  });

  testWidgets('S-118 AC5: unknown collect target shows the empty/error state', (tester) async {
    await _pumpCollectScreen(
      tester,
      user: null,
      businessError: ApiException('Business not found', statusCode: 404),
    );

    expect(find.byKey(const Key('collectReviewBodyField')), findsNothing);
    expect(find.textContaining('Business not found'), findsOneWidget);
  });
}
