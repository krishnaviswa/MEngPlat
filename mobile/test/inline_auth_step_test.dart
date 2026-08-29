import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/features/reviews/inline_auth_step.dart';

/// S-121 AC4/AC5/AC9, component-level: `InlineAuthStep` on its own (not
/// through the full collect screen) -- all three sign-in methods are present
/// and functional, Mobile OTP (not password) is the pre-selected default, and
/// a failed attempt surfaces an inline error without signing in.

class _ConfiguredGoogleClient implements GoogleSignInClient {
  @override
  bool get isConfigured => true;
  @override
  Future<String?> requestIdToken() async => 'google-credential-token';
}

class _FakeAuthController extends AuthController {
  _FakeAuthController();

  Object? credentialsError;
  int credentialsCalls = 0;

  @override
  Future<UserResponse?> build() async => null;

  @override
  Future<LoginResult> submitCredentials({required String email, required String password}) async {
    credentialsCalls++;
    final err = credentialsError;
    if (err != null) throw err;
    return LoginResult((b) => b
      ..accessToken = 'a'
      ..refreshToken = 'r');
  }
}

Future<_FakeAuthController> _pumpInlineAuthStep(WidgetTester tester) async {
  final auth = _FakeAuthController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        googleSignInClientProvider.overrideWith((ref) async => _ConfiguredGoogleClient()),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: InlineAuthStep()))),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets(
    'AC4/AC5: Mobile OTP is pre-selected by default (not password), and Google is shown regardless of the toggle',
    (tester) async {
      await _pumpInlineAuthStep(tester);

      expect(find.text('Sign in to post your review'), findsOneWidget);
      // Default method is OTP: its panel is already visible...
      expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
      // ...and the password fields are not, confirming password is not the default (AC5).
      expect(find.byKey(const Key('inlineAuthEmailField')), findsNothing);
      expect(find.byKey(const Key('inlineAuthPasswordField')), findsNothing);
      // Google is present unconditionally alongside the OTP-default panel (AC4).
      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
      expect(find.byKey(const Key('inlineAuthMethodOtp')), findsOneWidget);
      expect(find.byKey(const Key('inlineAuthMethodPassword')), findsOneWidget);

      // Toggle reaches email+password (AC4: all three methods present and reachable).
      await tester.tap(find.byKey(const Key('inlineAuthMethodPassword')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inlineAuthEmailField')), findsOneWidget);
      expect(find.byKey(const Key('inlineAuthPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('phoneNumberField')), findsNothing);
      // Google stays present after toggling to password too -- unconditional (AC4).
      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    },
  );

  testWidgets('AC9: wrong password+email credentials show an inline error and do not sign in', (tester) async {
    final auth = await _pumpInlineAuthStep(tester);
    auth.credentialsError = ApiException('Incorrect email or password', statusCode: 401);

    await tester.tap(find.byKey(const Key('inlineAuthMethodPassword')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('inlineAuthEmailField')), 'wrong@example.com');
    await tester.enterText(find.byKey(const Key('inlineAuthPasswordField')), 'wrong-password');
    await tester.pump();
    await tester.tap(find.byKey(const Key('inlineAuthPasswordSubmitButton')));
    await tester.pumpAndSettle();

    expect(auth.credentialsCalls, 1);
    expect(find.textContaining('Incorrect email or password'), findsOneWidget);
    // Stays on the credentials step -- no MFA/verify step reached, nothing signed in.
    expect(find.byKey(const Key('inlineAuthEmailField')), findsOneWidget);
    expect(find.byKey(const Key('inlineAuthCodeField')), findsNothing);
  });
}
