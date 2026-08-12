import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_detail_screen.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

/// S-023 AC1/AC3/AC4/AC6/AC10/AC12/AC13: the business detail screen's header
/// + reviews list + "Add review" eligibility gating (already-reviewed, own
/// business, logged-out).

BusinessResponse _business({String id = 'biz-1', String slug = 'test-biz', String name = "Joe's Diner"}) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = name
    ..slug = slug
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..country = 'US'
    ..status = BusinessStatus.approved
    ..averageRating = 4.2
    ..reviewCount = 3);
}

ReviewResponse _review({required String id, required String authorId}) {
  return ReviewResponse((b) => b
    ..id = id
    ..businessId = 'biz-1'
    ..authorId = authorId
    ..rating = 5
    ..body = 'A perfectly fine review body for testing purposes.'
    ..status = ReviewStatus.active
    ..likeCount = 0
    ..createdAt = DateTime.utc(2026, 1, 1));
}

UserResponse _user({required String id, required UserRole role}) {
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
  _FakeBusinessRepository({this.business, this.mine = const [], this.detailError}) : super(ApiClient());

  final BusinessResponse? business;
  final List<BusinessResponse> mine;
  final Object? detailError;

  @override
  Future<BusinessResponse> getBySlug(String slug) async {
    final error = detailError;
    if (error != null) throw error;
    return business ?? _business();
  }

  @override
  Future<List<BusinessResponse>> listMine() async => mine;
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.reviews = const [], this.listError}) : super(ApiClient());

  final List<ReviewResponse> reviews;
  final Object? listError;
  int listCalls = 0;

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async {
    listCalls++;
    final error = listError;
    if (error != null) throw error;
    return reviews;
  }
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

Future<_FakeReviewRepository> _pumpDetailScreen(
  WidgetTester tester, {
  required UserResponse? user,
  BusinessResponse? business,
  List<ReviewResponse> reviews = const [],
  List<BusinessResponse> mine = const [],
  Object? businessError,
  Object? reviewsError,
}) async {
  final reviewRepository = _FakeReviewRepository(reviews: reviews, listError: reviewsError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(
        _FakeBusinessRepository(business: business, mine: mine, detailError: businessError),
      ),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/businesses/test-biz',
    routes: [
      GoRoute(
        path: '/businesses/:slug',
        builder: (context, state) => BusinessDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('LOGIN_SCREEN'))),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return reviewRepository;
}

void main() {
  testWidgets('AC1: shows business name, average rating, review count and its reviews', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'cust-1', role: UserRole.customer),
      business: _business(name: "Joe's Diner"),
      reviews: [_review(id: 'r1', authorId: 'other')],
    );

    expect(find.text("Joe's Diner"), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('3 reviews'), findsOneWidget);
  });

  testWidgets('AC3: shows an empty-state message when the business has zero reviews', (tester) async {
    await _pumpDetailScreen(tester, user: _user(id: 'cust-1', role: UserRole.customer), reviews: const []);

    expect(find.textContaining('No reviews yet'), findsOneWidget);
  });

  testWidgets('AC4: shows an inline error with a Retry action when the reviews request fails', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'cust-1', role: UserRole.customer),
      reviewsError: ApiException('Network error'),
    );

    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('AC6: shows "Add review" for an eligible customer who has not reviewed yet', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'cust-1', role: UserRole.customer),
      reviews: [_review(id: 'r1', authorId: 'someone-else')],
    );

    expect(find.byKey(const Key('addReviewButton')), findsOneWidget);
  });

  testWidgets('AC10: hides "Add review" once the current user has already reviewed this business', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'cust-1', role: UserRole.customer),
      reviews: [_review(id: 'r1', authorId: 'cust-1')],
    );

    expect(find.byKey(const Key('addReviewButton')), findsNothing);
  });

  testWidgets('AC12: hides "Add review" for a merchant viewing their own business', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'merchant-1', role: UserRole.merchant),
      business: _business(id: 'biz-1'),
      mine: [_business(id: 'biz-1')],
    );

    expect(find.byKey(const Key('addReviewButton')), findsNothing);
  });

  testWidgets('a merchant viewing a business they do not own still sees "Add review"', (tester) async {
    await _pumpDetailScreen(
      tester,
      user: _user(id: 'merchant-1', role: UserRole.merchant),
      business: _business(id: 'biz-1'),
      mine: [_business(id: 'some-other-biz')],
    );

    expect(find.byKey(const Key('addReviewButton')), findsOneWidget);
  });

  testWidgets('AC5: pull-to-refresh re-fetches the reviews list', (tester) async {
    final reviewRepository = await _pumpDetailScreen(
      tester,
      user: _user(id: 'cust-1', role: UserRole.customer),
      reviews: [_review(id: 'r1', authorId: 'other')],
    );
    expect(reviewRepository.listCalls, 1, reason: 'initial load');

    // Invoke the RefreshIndicator's onRefresh callback directly rather than
    // via RefreshIndicatorState.show()/a drag gesture: the latter drives a
    // real AnimationController that can hang a widget test indefinitely if
    // awaited without precisely-interleaved pump() calls. This still proves
    // the exact wiring under test (AC5's refetch trigger) deterministically.
    final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();
    await tester.pump();

    expect(reviewRepository.listCalls, 2, reason: 'pull-to-refresh must trigger a refetch');
  });

  testWidgets(
    'AC13: an anonymous visitor sees the reviews list, and tapping "Add review" routes to /login',
    (tester) async {
      await _pumpDetailScreen(tester, user: null, reviews: [_review(id: 'r1', authorId: 'someone')]);

      // Reviews are visible without a session.
      expect(find.textContaining('A perfectly fine review body'), findsOneWidget);
      expect(find.byKey(const Key('addReviewButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('addReviewButton')));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    },
  );
}
