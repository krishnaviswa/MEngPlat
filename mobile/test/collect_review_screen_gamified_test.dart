import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/reviews/collect_review_screen.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

/// S-119: the tap-through gamified flow, only reachable in this test suite by
/// running with `--dart-define=GAMIFIED_REVIEW=true` (see
/// `mobile/lib/core/config/app_config.dart`). Without that define,
/// `AppConfig.gamifiedReview` is false and this whole suite is skipped --
/// `collect_review_screen_test.dart` already covers the flag-off regression
/// path unconditionally.

BusinessResponse _business({String id = 'biz-1', String slug = 'joes-diner'}) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = "Joe's Diner"
    ..slug = slug
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..country = 'US'
    ..status = BusinessStatus.approved
    ..averageRating = 4.5
    ..reviewCount = 2);
}

UserResponse _user() {
  return UserResponse((b) => b
    ..id = 'cust-1'
    ..email = 'cust-1@example.com'
    ..fullName = 'Test User'
    ..role = UserRole.customer
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
  _FakeBusinessRepository() : super(ApiClient());
  @override
  Future<BusinessResponse> getBySlug(String slug) async => _business(slug: slug);
  @override
  Future<BusinessResponse> getById(String businessId) async => _business(id: businessId);
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.failNextCreate = false}) : super(ApiClient());
  bool failNextCreate;
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
    if (failNextCreate) {
      failNextCreate = false;
      throw Exception('Network error');
    }
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

void main() {
  if (!const bool.fromEnvironment('GAMIFIED_REVIEW')) {
    test('skipped: run with --dart-define=GAMIFIED_REVIEW=true to exercise the gamified flow', () {});
    return;
  }

  Future<_FakeReviewRepository> pumpGamified(
    WidgetTester tester, {
    required UserResponse? user,
    bool failNextCreate = false,
  }) async {
    final reviewRepository = _FakeReviewRepository(failNextCreate: failNextCreate);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(user)),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(reviewRepository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/collect/joes-diner',
      routes: [
        GoRoute(path: '/collect/:slug', builder: (context, state) => CollectReviewScreen(slug: state.pathParameters['slug']!)),
        GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('LOGIN'))),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await container.read(authControllerProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    return reviewRepository;
  }

  testWidgets('walks stars -> text one screen at a time, low ratings not gated', (tester) async {
    await pumpGamified(tester, user: _user());

    expect(find.byKey(const Key('collectReviewBodyField')), findsNothing);
    await tester.tap(find.byKey(const Key('ratingStar1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collectReviewBodyField')), findsOneWidget);
  });

  testWidgets('submits through the existing API and shows a celebration before the normal success screen', (tester) async {
    final repository = await pumpGamified(tester, user: _user());

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Loved the espresso here.');
    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastRating, 5);
    expect(find.byKey(const Key('collectReviewCelebration')), findsOneWidget);
    expect(find.byKey(const Key('collectReviewSuccess')), findsNothing);

    await tester.tap(find.byKey(const Key('collectReviewCelebrationContinue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collectReviewSuccess')), findsOneWidget);
  });

  testWidgets('shows an inline error and stays on the text step when submission fails, so the customer can retry', (
    tester,
  ) async {
    final repository = await pumpGamified(tester, user: _user(), failNextCreate: true);

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Loved the espresso here.');
    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.textContaining('Network error'), findsOneWidget);
    expect(find.byKey(const Key('collectReviewBodyField')), findsOneWidget);
    expect(find.byKey(const Key('collectReviewCelebration')), findsNothing);

    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 2);
    expect(find.byKey(const Key('collectReviewCelebration')), findsOneWidget);
  });
}
