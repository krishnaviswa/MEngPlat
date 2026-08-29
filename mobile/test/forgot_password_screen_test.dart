import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/router.dart';
import 'watch_router_app.dart';

/// S-054 (M-65): mobile forgot/reset password, request half only. Pumps the
/// full app router (like register_google_auth_test.dart) since
/// ForgotPasswordScreen and login_screen.dart's new link both call
/// `context.go`, and the router redirect carve-out itself is part of the
/// slice's AC coverage.
class _FakeAuthController extends AuthController {
  _FakeAuthController({this.forgotPasswordError});

  /// Mutable so tests can flip a failing call into a succeeding one to prove
  /// the retry path genuinely re-invokes the API rather than caching a
  /// permanent failure state.
  Object? forgotPasswordError;
  String? lastForgotPasswordEmail;

  @override
  Future<UserResponse?> build() async => null;

  @override
  Future<MessageResponse> forgotPassword({required String email}) async {
    lastForgotPasswordEmail = email;
    if (forgotPasswordError != null) throw forgotPasswordError!;
    return MessageResponse(
      (b) => b..message = 'If an account exists for that email, we sent password-reset instructions.',
    );
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

/// The login screen defaults to the OTP method (S-092): the email/password
/// credentials fields and the "Forgot password?" link below them only render
/// once the Password method is selected, which is the path a password user
/// takes to reach the reset flow.
Future<void> _selectPasswordMethod(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('loginMethodPassword')));
  await _pumpFrames(tester);
}

/// From a freshly pumped app: switch to Password login, then open the
/// forgot-password screen via its link.
Future<void> _openForgotPassword(WidgetTester tester) async {
  await _selectPasswordMethod(tester);
  await tester.ensureVisible(find.byKey(const Key('forgotPasswordLink')));
  await tester.tap(find.byKey(const Key('forgotPasswordLink')));
  await _pumpFrames(tester);
}

Future<({ProviderContainer container, _FakeAuthController auth})> _pumpApp(
  WidgetTester tester, {
  Object? forgotPasswordError,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController(forgotPasswordError: forgotPasswordError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      googleSignInClientProvider.overrideWith((ref) async => const UnconfiguredGoogleSignInClient()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const WatchRouterApp(),
    ),
  );
  await _pumpFrames(tester);
  return (container: container, auth: auth);
}

void main() {
  testWidgets('AC1: forgotPasswordLink is visible below the Password credentials fields', (tester) async {
    final result = await _pumpApp(tester);
    await _selectPasswordMethod(tester);
    expect(find.byKey(const Key('forgotPasswordLink')), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    result.container.dispose();
  });

  testWidgets('AC2: tapping the link opens a screen with only an email field and submit button', (tester) async {
    final result = await _pumpApp(tester);
    await _openForgotPassword(tester);

    expect(find.text('Forgot password'), findsWidgets);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('submitButton')), findsOneWidget);
    // No other input fields (password, name, etc.) on this screen.
    expect(find.byKey(const Key('passwordField')), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('router carve-out: unauthenticated user navigating to /forgot-password is not bounced to /login',
      (tester) async {
    final result = await _pumpApp(tester);
    result.container.read(routerProvider).go('/forgot-password');
    await _pumpFrames(tester);

    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('submitButton')), findsOneWidget);
    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC3/AC5: submitting a well-formed email shows the generic confirmation and browser instruction',
      (tester) async {
    final result = await _pumpApp(tester);
    await _openForgotPassword(tester);

    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpFrames(tester);

    expect(result.auth.lastForgotPasswordEmail, 'user@example.com');
    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsOneWidget);
    expect(
      find.text('If an account exists for that email, we sent password-reset instructions.'),
      findsOneWidget,
    );
    // AC5: no in-app reset screen -- confirmation instructs opening the
    // emailed link in the phone's browser instead.
    expect(find.textContaining("phone's browser"), findsOneWidget);
    // Form is gone, replaced by the confirmation state.
    expect(find.byKey(const Key('emailField')), findsNothing);
    expect(find.byKey(const Key('submitButton')), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC3: confirmation copy is identical for an unknown/unregistered-looking email (no enumeration)',
      (tester) async {
    final result = await _pumpApp(tester);
    await _openForgotPassword(tester);

    await tester.enterText(find.byKey(const Key('emailField')), 'never-registered@example.com');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpFrames(tester);

    expect(
      find.text('If an account exists for that email, we sent password-reset instructions.'),
      findsOneWidget,
    );

    result.container.dispose();
  });

  testWidgets('AC4: network/5xx failure shows a generic error and allows retry; never silently succeeds',
      (tester) async {
    final result = await _pumpApp(tester, forgotPasswordError: ApiException('Service unavailable', statusCode: 503));
    await _openForgotPassword(tester);

    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('forgotPasswordError')), findsOneWidget);
    expect(find.textContaining('Service unavailable'), findsOneWidget);
    // Stays on the form -- no confirmation state reached on failure.
    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsNothing);
    expect(find.byKey(const Key('submitButton')), findsOneWidget);

    // Retry: fix the fake so the next submit succeeds, proving the retry
    // path genuinely re-invokes the API call rather than getting stuck.
    result.auth.forgotPasswordError = null;
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC6: Back to sign in from the form state returns to /login without submitting', (tester) async {
    final result = await _pumpApp(tester);
    await _openForgotPassword(tester);

    await tester.tap(find.byKey(const Key('backToSignInLink')));
    await _pumpFrames(tester);

    expect(result.auth.lastForgotPasswordEmail, isNull);
    // Back on a fresh login screen (its method selector is present); the
    // forgot-password screen is gone.
    expect(find.byKey(const Key('loginMethodPassword')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC6: Back to sign in from the confirmation state also returns to /login', (tester) async {
    final result = await _pumpApp(tester);
    await _openForgotPassword(tester);
    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsOneWidget);
    await tester.tap(find.byKey(const Key('backToSignInLink')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('loginMethodPassword')), findsOneWidget);
    expect(find.byKey(const Key('forgotPasswordConfirmation')), findsNothing);

    result.container.dispose();
  });
}
