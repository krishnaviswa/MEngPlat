import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';
import 'package:merchanthub_mobile/router.dart';

UserResponse _makeUser(UserRole role, {String email = 'user@example.com', String name = 'Test User'}) =>
    UserResponse((b) => b
      ..id = 'user-1'
      ..email = email
      ..fullName = name
      ..role = role
      ..isActive = true
      ..createdAt = DateTime.utc(2026, 1, 1));

class _RegisterCall {
  _RegisterCall({required this.email, required this.fullName, required this.password, required this.role});
  final String email;
  final String fullName;
  final String password;
  final UserRole role;
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(
    this._user, {
    this.registerError,
    this.googleUser,
  });

  UserResponse? _user;
  Object? registerError;
  UserResponse? googleUser;
  _RegisterCall? lastRegister;
  String? lastGoogleCredential;

  @override
  Future<UserResponse?> build() async => _user;

  @override
  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    required UserRole role,
  }) async {
    if (registerError != null) throw registerError!;
    lastRegister = _RegisterCall(email: email, fullName: fullName, password: password, role: role);
  }

  @override
  Future<void> signInWithGoogle({required String credential}) async {
    lastGoogleCredential = credential;
    final signedIn = googleUser ?? _makeUser(UserRole.customer, email: 'google@example.com', name: 'Gmail User');
    _user = signedIn;
    state = AsyncValue.data(signedIn);
  }

  @override
  Future<void> logout() async {
    _user = null;
    state = const AsyncValue.data(null);
  }
}

class _FakeGoogleClient implements GoogleSignInClient {
  _FakeGoogleClient({this.credential = 'google-id-token', this.cancel = false});

  final String credential;
  final bool cancel;

  @override
  bool get isConfigured => true;

  @override
  Future<String?> requestIdToken() async => cancel ? null : credential;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> searchBusinesses({SearchQuery query = const SearchQuery(), int page = 1, int pageSize = SearchQuery.pageSize}) async => [];
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

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async => [];
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<({ProviderContainer container, _FakeAuthController auth})> _pumpApp(
  WidgetTester tester, {
  UserResponse? user,
  GoogleSignInClient? google,
  Object? registerError,
  UserResponse? googleUser,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController(user, registerError: registerError, googleUser: googleUser);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      googleSignInClientProvider.overrideWithValue(google ?? const UnconfiguredGoogleSignInClient()),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
      notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
      favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
      reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: container.read(routerProvider)),
    ),
  );
  await _pumpFrames(tester);
  return (container: container, auth: auth);
}

Future<void> _fillRegisterForm(
  WidgetTester tester, {
  String name = 'Casey Customer',
  String email = 'casey@example.com',
  String password = 'password1234',
}) async {
  await tester.enterText(find.byKey(const Key('registerFullNameField')), name);
  await tester.enterText(find.byKey(const Key('registerEmailField')), email);
  await tester.enterText(find.byKey(const Key('registerPasswordField')), password);
}

void main() {
  testWidgets('AC7/AC8/AC20: Create account opens register outside the shell; Sign in returns', (tester) async {
    final result = await _pumpApp(tester);
    expect(find.byKey(const Key('primaryNav')), findsNothing);
    expect(find.byKey(const Key('createAccountLink')), findsOneWidget);

    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);

    expect(find.text('Create account'), findsWidgets);
    expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    expect(find.byKey(const Key('primaryNav')), findsNothing);
    expect(find.byKey(const Key('signInLink')), findsOneWidget);

    await tester.tap(find.byKey(const Key('signInLink')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('submitButton')), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);

    result.container.dispose();
  });

  testWidgets('AC1/AC6: customer register lands on login with note and prefilled email; no session', (tester) async {
    final result = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    await _fillRegisterForm(tester);
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastRegister?.role, UserRole.customer);
    expect(result.auth.lastRegister?.email, 'casey@example.com');
    expect(find.byKey(const Key('registeredNote')), findsOneWidget);
    expect(find.text('casey@example.com'), findsOneWidget);
    expect(find.byKey(const Key('mfaCodeField')), findsNothing);
    expect(result.auth._user, isNull);

    result.container.dispose();
  });

  testWidgets('AC2/AC3: merchant register is offered; admin is not', (tester) async {
    final result = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('roleDropdown')), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);

    await tester.tap(find.byKey(const Key('roleDropdown')));
    await _pumpFrames(tester);
    expect(find.text('Merchant'), findsWidgets);
    await tester.tap(find.text('Merchant').last);
    await _pumpFrames(tester);
    await _fillRegisterForm(tester, email: 'mina@example.com', name: 'Mina Merchant');
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastRegister?.role, UserRole.merchant);
    expect(find.byKey(const Key('registeredNote')), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC4: duplicate email stays on register with error', (tester) async {
    final result = await _pumpApp(tester, registerError: ApiException('Email already registered'));
    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    await _fillRegisterForm(tester);
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('registerError')), findsOneWidget);
    expect(find.textContaining('Email already registered'), findsOneWidget);
    expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    expect(find.byKey(const Key('registeredNote')), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC5: invalid email and short password block submit', (tester) async {
    final result = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('registerFullNameField')), 'Casey');
    await tester.enterText(find.byKey(const Key('registerEmailField')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('registerPasswordField')), 'short');
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastRegister, isNull);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password is too short'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC11/AC18: Google button hidden when unconfigured; skip-MFA copy still shown', (tester) async {
    final result = await _pumpApp(tester);
    expect(find.byKey(const Key('googleSignInButton')), findsNothing);
    expect(find.textContaining('Gmail sign-in below skips that step'), findsOneWidget);

    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('googleSignInButton')), findsNothing);
    expect(find.textContaining('Gmail sign-in below skips that step'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC9: Google on login issues a session without TOTP and lands Explore', (tester) async {
    final googleUser = _makeUser(UserRole.customer, email: 'gmail@example.com', name: 'Gmail User');
    final result = await _pumpApp(
      tester,
      google: _FakeGoogleClient(),
      googleUser: googleUser,
    );

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastGoogleCredential, 'google-id-token');
    expect(find.byKey(const Key('mfaCodeField')), findsNothing);
    expect(find.text('Businesses'), findsOneWidget);
    expect(find.byKey(const Key('exploreTab')), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC10: Google on register creates a customer session without TOTP', (tester) async {
    final googleUser = _makeUser(UserRole.customer, email: 'gmail@example.com', name: 'Gmail User');
    final result = await _pumpApp(
      tester,
      google: _FakeGoogleClient(credential: 'reg-id-token'),
      googleUser: googleUser,
    );
    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastGoogleCredential, 'reg-id-token');
    expect(find.byKey(const Key('mfaCodeField')), findsNothing);
    expect(find.text('Businesses'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC12: dismissing Google stays signed out with no error', (tester) async {
    final result = await _pumpApp(tester, google: _FakeGoogleClient(cancel: true));
    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastGoogleCredential, isNull);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('registerError')), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC16: guest /account/profile redirects to login', (tester) async {
    final result = await _pumpApp(tester);
    result.container.read(routerProvider).go('/account/profile');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('profileScreen')), findsNothing);
    result.container.dispose();
  });
}
