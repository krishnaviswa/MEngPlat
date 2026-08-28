import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/reviews/collect_review_screen.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

/// S-121 AC6/AC7/AC9/AC10, screen-level: complements the "shows inline step,
/// no route push" regression case already in collect_review_screen_test.dart
/// by driving the inline auth step's own Google/OTP paths to completion and
/// asserting the `ref.listen`-driven auto-submit (ADR-018) -- the composed
/// rating/body reach `POST /reviews` untouched and the customer lands on the
/// existing success screen with no form re-shown and no re-entry.

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
  _FakeAuthController();

  int googleCalls = 0;
  int phoneCalls = 0;
  Object? googleError;
  Object? phoneError;

  @override
  Future<UserResponse?> build() async => null;

  @override
  Future<void> signInWithGoogle({required String credential}) async {
    googleCalls++;
    final err = googleError;
    if (err != null) throw err;
    state = AsyncValue.data(_user());
  }

  @override
  Future<MessageResponse> requestPhoneOtp({required String phone}) async {
    return MessageResponse((b) => b..message = 'sent');
  }

  @override
  Future<void> signInWithPhone({
    required String phone,
    required String code,
    String? fullName,
    UserRole? role,
  }) async {
    phoneCalls++;
    final err = phoneError;
    if (err != null) throw err;
    state = AsyncValue.data(_user());
  }
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());
  @override
  Future<BusinessResponse> getBySlug(String slug) async => _business(slug: slug);
  @override
  Future<BusinessResponse> getById(String businessId) async => _business(id: businessId);
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());
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

class _ConfiguredGoogleClient implements GoogleSignInClient {
  @override
  bool get isConfigured => true;
  @override
  Future<String?> requestIdToken() async => 'google-credential-token';
}

Future<_FakeReviewRepository> _pumpCollect(WidgetTester tester, {required _FakeAuthController auth}) async {
  final reviewRepository = _FakeReviewRepository();
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
      reviewRepositoryProvider.overrideWithValue(reviewRepository),
      googleSignInClientProvider.overrideWith((ref) async => _ConfiguredGoogleClient()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/collect/joes-diner',
    routes: [
      GoRoute(
        path: '/collect/:slug',
        builder: (context, state) => CollectReviewScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => Scaffold(body: Text('LOGIN next=${state.uri.queryParameters['next']}')),
      ),
    ],
  );

  await tester.binding.setSurfaceSize(const Size(500, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await container.read(authControllerProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
  return reviewRepository;
}

void main() {
  testWidgets(
    'AC6/AC7: Google sign-in from the inline step auto-submits the composed review and lands on the success '
    'screen, no re-entry',
    (tester) async {
      final auth = _FakeAuthController();
      final repository = await _pumpCollect(tester, auth: auth);

      await tester.tap(find.byKey(const Key('ratingStar5')));
      await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Great walk-in service today.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to post your review'), findsOneWidget);
      expect(repository.createCalls, 0);

      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pumpAndSettle();

      expect(auth.googleCalls, 1);
      expect(repository.createCalls, 1);
      expect(repository.lastRating, 5);
      expect(repository.lastBody, 'Great walk-in service today.');
      expect(find.byKey(const Key('collectReviewSuccess')), findsOneWidget);
      // No re-entry: neither the inline auth step nor the compose form reappear.
      expect(find.text('Sign in to post your review'), findsNothing);
      expect(find.byKey(const Key('collectReviewBodyField')), findsNothing);
    },
  );

  testWidgets(
    'AC6/AC7 (default method): phone OTP -- the pre-selected inline auth default (AC5) -- also auto-submits '
    'the composed review',
    (tester) async {
      final auth = _FakeAuthController();
      final repository = await _pumpCollect(tester, auth: auth);

      await tester.tap(find.byKey(const Key('ratingStar4')));
      await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Quick and friendly staff.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
      await tester.pumpAndSettle();

      // AC5: OTP is already the visible method -- no toggle tap needed.
      expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('phoneNumberField')), '9876543210');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendPhoneCodeButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(auth.phoneCalls, 1);
      expect(repository.createCalls, 1);
      expect(repository.lastRating, 4);
      expect(repository.lastBody, 'Quick and friendly staff.');
      expect(find.byKey(const Key('collectReviewSuccess')), findsOneWidget);
    },
  );

  testWidgets(
    'AC9: a failed inline sign-in shows an inline error and stays on the collect screen -- no navigation, no '
    'submit -- and a later successful attempt still submits the same composed review, proving it was never lost',
    (tester) async {
      final auth = _FakeAuthController()..googleError = ApiException('Sign-in failed', statusCode: 401);
      final repository = await _pumpCollect(tester, auth: auth);

      await tester.tap(find.byKey(const Key('ratingStar3')));
      await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'It was okay, could improve.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pumpAndSettle();

      expect(auth.googleCalls, 1);
      expect(repository.createCalls, 0, reason: 'a failed sign-in must not submit');
      expect(find.textContaining('Sign-in failed'), findsOneWidget);
      // Still on the collect screen -- no route push to /login, inline step stays shown.
      expect(find.byKey(const Key('collectReviewScreen')), findsOneWidget);
      expect(find.text('Sign in to post your review'), findsOneWidget);
      expect(find.textContaining('LOGIN next='), findsNothing);

      // Retry succeeds -- proves the composed rating/body survived the failed attempt untouched (AC9).
      auth.googleError = null;
      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(repository.lastRating, 3);
      expect(repository.lastBody, 'It was okay, could improve.');
    },
  );

  Future<void> expectIdenticalGateForRating(WidgetTester tester, int rating) async {
    final auth = _FakeAuthController();
    await _pumpCollect(tester, auth: auth);

    await tester.tap(find.byKey(Key('ratingStar$rating')));
    await tester.enterText(find.byKey(const Key('collectReviewBodyField')), 'Composed body for rating $rating.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('collectReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to post your review'), findsOneWidget);
    expect(find.byKey(const Key('inlineAuthMethodOtp')), findsOneWidget);
    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
  }

  // AC10 (S-040's no-rating-gating rule reaffirmed): two separate widget
  // trees, one per rating, rather than looping a `pumpWidget` twice inside a
  // single `testWidgets` -- reusing one live tree for a second, unrelated
  // provider container/tree left a dangling cursor-blink Timer that tripped
  // flutter_test's "no pending timers after dispose" invariant.
  testWidgets('AC10: the inline auth gate for a 1-star composed review', (tester) async {
    await expectIdenticalGateForRating(tester, 1);
  });

  testWidgets('AC10: the inline auth gate for a 5-star composed review is identical to the 1-star case', (
    tester,
  ) async {
    await expectIdenticalGateForRating(tester, 5);
  });
}
