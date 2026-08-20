import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/features/auth/login_screen.dart';
import 'package:merchanthub_mobile/features/auth/phone_otp_panel.dart';
import 'package:merchanthub_mobile/features/auth/register_screen.dart';

/// S-055 (M-74): mobile phone OTP sign-in. Follows widget_test.dart's plain
/// `MaterialApp(home: ...)` pattern (no full router needed -- neither
/// PhoneOtpPanel nor a successful sign-in triggers `context.go` directly;
/// the app router's own redirect takes over once `authControllerProvider`
/// flips to a real user, which is out of scope for this panel-level test
/// and is exercised indirectly by asserting the provider state instead).
class _FakeAuthController extends AuthController {
  _FakeAuthController({this.requestError, this.verifyError});

  Object? requestError;
  Object? verifyError;
  String? lastRequestPhone;
  String? lastVerifyPhone;
  String? lastVerifyCode;
  String? lastVerifyFullName;
  UserRole? lastVerifyRole;
  int verifyCallCount = 0;

  @override
  Future<UserResponse?> build() async => null;

  @override
  Future<MessageResponse> requestPhoneOtp({required String phone}) async {
    lastRequestPhone = phone;
    if (requestError != null) throw requestError!;
    return MessageResponse((b) => b..message = 'If that number can receive SMS, we sent a sign-in code.');
  }

  @override
  Future<void> signInWithPhone({
    required String phone,
    required String code,
    String? fullName,
    UserRole? role,
  }) async {
    verifyCallCount++;
    lastVerifyPhone = phone;
    lastVerifyCode = code;
    lastVerifyFullName = fullName;
    lastVerifyRole = role;
    if (verifyError != null) throw verifyError!;
    final user = UserResponse((b) => b
      ..id = 'user-phone-1'
      ..fullName = fullName ?? 'Phone User'
      ..role = role ?? UserRole.customer
      ..isActive = true
      ..phone = phone
      ..createdAt = DateTime.utc(2026, 1, 1));
    state = AsyncValue.data(user);
  }
}

Future<({ProviderContainer container, _FakeAuthController auth})> _pumpWidget(
  WidgetTester tester,
  Widget child, {
  Object? requestError,
  Object? verifyError,
}) async {
  // LoginScreen/RegisterScreen are tall forms with the phone panel below the
  // fold at the default 800x600 test surface; size up so tap()/enterText()
  // on the panel's fields don't hit-test outside the render tree.
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController(requestError: requestError, verifyError: verifyError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      googleSignInClientProvider.overrideWith((ref) async => const UnconfiguredGoogleSignInClient()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, auth: auth);
}

Future<void> _sendCode(WidgetTester tester, {String number = '9876543210'}) async {
  await tester.enterText(find.byKey(const Key('phoneNumberField')), number);
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendPhoneCodeButton')));
  await tester.pumpAndSettle();
}

Future<void> _selectLoginPhone(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('loginMethodPhone')));
  await tester.pumpAndSettle();
}

void main() {
  group('PhoneOtpPanel standalone (default fullName/role null, as on login)', () {
    testWidgets('AC1: shows country code selector (+91 default), number field, and Send SMS code button',
        (tester) async {
      final result = await _pumpWidget(tester, const Scaffold(body: PhoneOtpPanel()));

      expect(find.byKey(const Key('phoneCountryCodeField')), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
      expect(find.byKey(const Key('sendPhoneCodeButton')), findsOneWidget);
      expect(find.text('Send SMS code'), findsOneWidget);
      // Code field/verify button not shown until a code has been sent.
      expect(find.byKey(const Key('phoneCodeField')), findsNothing);
      expect(find.byKey(const Key('verifyPhoneCodeButton')), findsNothing);

      result.container.dispose();
    });

    testWidgets('Send SMS code is disabled until a number is entered', (tester) async {
      final result = await _pumpWidget(tester, const Scaffold(body: PhoneOtpPanel()));

      final buttonBefore = tester.widget<FilledButton>(find.byKey(const Key('sendPhoneCodeButton')));
      expect(buttonBefore.onPressed, isNull);

      await tester.enterText(find.byKey(const Key('phoneNumberField')), '9876543210');
      await tester.pump();
      final buttonAfter = tester.widget<FilledButton>(find.byKey(const Key('sendPhoneCodeButton')));
      expect(buttonAfter.onPressed, isNotNull);

      result.container.dispose();
    });

    testWidgets('country code selector: switching to +1 concatenates it into the request', (tester) async {
      final result = await _pumpWidget(tester, const Scaffold(body: PhoneOtpPanel()));

      await tester.tap(find.byKey(const Key('phoneCountryCodeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1').last);
      await tester.pumpAndSettle();

      await _sendCode(tester, number: '5551234567');
      expect(result.auth.lastRequestPhone, '+15551234567');

      result.container.dispose();
    });

    testWidgets(
        'AC3: sending a code always shows the generic confirmation flow and reveals code field + verify button',
        (tester) async {
      final result = await _pumpWidget(tester, const Scaffold(body: PhoneOtpPanel()));

      await _sendCode(tester);

      expect(result.auth.lastRequestPhone, '+919876543210');
      expect(find.byKey(const Key('phoneCodeField')), findsOneWidget);
      expect(find.byKey(const Key('verifyPhoneCodeButton')), findsOneWidget);
      // Send button/number field step is replaced by the code step.
      expect(find.byKey(const Key('sendPhoneCodeButton')), findsNothing);

      result.container.dispose();
    });

    testWidgets('Verify and sign in is disabled until the code field has at least 4 characters', (tester) async {
      final result = await _pumpWidget(tester, const Scaffold(body: PhoneOtpPanel()));
      await _sendCode(tester);

      final buttonBefore = tester.widget<FilledButton>(find.byKey(const Key('verifyPhoneCodeButton')));
      expect(buttonBefore.onPressed, isNull);

      await tester.enterText(find.byKey(const Key('phoneCodeField')), '123');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('verifyPhoneCodeButton'))).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('phoneCodeField')), '1234');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('verifyPhoneCodeButton'))).onPressed, isNotNull);

      result.container.dispose();
    });

    testWidgets('AC6: invalid/expired code (401) shows a plain error and the code field remains editable for retry',
        (tester) async {
      final result = await _pumpWidget(
        tester,
        const Scaffold(body: PhoneOtpPanel()),
        verifyError: ApiException('Invalid or expired code', statusCode: 401),
      );
      await _sendCode(tester);
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '000000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('phoneOtpError')), findsOneWidget);
      expect(find.textContaining('Invalid or expired code'), findsOneWidget);
      expect(find.byKey(const Key('phoneCodeField')), findsOneWidget);
      expect(find.text('000000'), findsOneWidget);

      // Retry with the field still editable.
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '111111');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('verifyPhoneCodeButton'))).onPressed, isNotNull);

      result.container.dispose();
    });
  });

  group('PhoneOtpPanel embedded in LoginScreen (no fullName/role passed)', () {
    testWidgets('AC1: panel is present below the credentials fields', (tester) async {
      final result = await _pumpWidget(tester, const LoginScreen());
      await _selectLoginPhone(tester);
      expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
      expect(find.byKey(const Key('sendPhoneCodeButton')), findsOneWidget);
      result.container.dispose();
    });

    testWidgets('AC5: verifying a brand-new number from login omits full_name unless the optional name is filled',
        (tester) async {
      final result = await _pumpWidget(tester, const LoginScreen());
      await _selectLoginPhone(tester);
      await _sendCode(tester);
      expect(find.byKey(const Key('phoneOptionalNameField')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(result.auth.lastVerifyFullName, isNull);
      expect(result.auth.lastVerifyRole, isNull);
      expect(find.byKey(const Key('registerFullNameField')), findsNothing);

      result.container.dispose();
    });

    testWidgets('successful verify from login flips authControllerProvider to a signed-in user', (tester) async {
      final result = await _pumpWidget(tester, const LoginScreen());
      await _selectLoginPhone(tester);
      await _sendCode(tester);
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(result.auth.lastVerifyPhone, '+919876543210');
      expect(result.auth.lastVerifyCode, '123456');
      expect(result.container.read(authControllerProvider).valueOrNull, isNotNull);

      result.container.dispose();
    });
  });

  group('PhoneOtpPanel embedded in RegisterScreen (fullName/role supplied from the in-progress form)', () {
    testWidgets('AC2: panel is present in the equivalent position on the register screen', (tester) async {
      final result = await _pumpWidget(tester, const RegisterScreen());
      expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
      expect(find.byKey(const Key('sendPhoneCodeButton')), findsOneWidget);
      result.container.dispose();
    });

    testWidgets('AC4: verify from register sends the in-progress full_name and role, updated live as name changes',
        (tester) async {
      final result = await _pumpWidget(tester, const RegisterScreen());

      // Type a first draft of the name, then change it -- proves the panel's
      // fullName prop is kept fresh via the _onNameChanged listener rather
      // than only picking up the value present when the widget was built.
      await tester.enterText(find.byKey(const Key('registerFullNameField')), 'Cas');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('registerFullNameField')), 'Casey Customer');
      await tester.pump();

      // Switch role to merchant, also mid-flow.
      await tester.tap(find.byKey(const Key('roleDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merchant').last);
      await tester.pumpAndSettle();

      await _sendCode(tester);
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '654321');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(result.auth.lastVerifyFullName, 'Casey Customer');
      expect(result.auth.lastVerifyRole, UserRole.merchant);
      expect(result.auth.verifyCallCount, 1);

      result.container.dispose();
    });

    testWidgets('AC4: on success the user is signed in (JWT/session state set), TOTP step skipped', (tester) async {
      final result = await _pumpWidget(tester, const RegisterScreen());
      await tester.enterText(find.byKey(const Key('registerFullNameField')), 'New Signup');
      await tester.pump();

      await _sendCode(tester);
      await tester.enterText(find.byKey(const Key('phoneCodeField')), '654321');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mfaCodeField')), findsNothing);
      expect(result.container.read(authControllerProvider).valueOrNull?.fullName, 'New Signup');

      result.container.dispose();
    });
  });
}
