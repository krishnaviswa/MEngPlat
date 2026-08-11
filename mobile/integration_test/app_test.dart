import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:merchanthub_mobile/app.dart';
import 'package:otp/otp.dart';

// Matches backend/app/services/mfa.py's DEMO_TOTP_SECRET, seeded onto every
// demo account (S-020 mandatory TOTP) via enable_demo_totp().
const _demoTotpSecret = 'JBSWY3DPEHPK3PXP';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and view business list', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MerchantHubApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'customer@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'customer123');
    await tester.tap(find.byKey(const Key('submitButton')));

    // Backend round trip for the credentials step against a freshly booted
    // CI backend can take a few seconds; wait for the MFA code field rather
    // than a fixed duration so this isn't flaky either way.
    await tester.pumpAndSettle(const Duration(seconds: 15));
    expect(find.byKey(const Key('mfaCodeField')), findsOneWidget);

    final code = OTP.generateTOTPCodeString(
      _demoTotpSecret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      interval: 30,
      length: 6,
      isGoogle: true,
    );
    await tester.enterText(find.byKey(const Key('mfaCodeField')), code);
    await tester.tap(find.byKey(const Key('submitButton')));

    // Backend round trips (verify -> me -> search) can take several seconds
    // against a freshly booted CI backend; give it real headroom.
    await tester.pumpAndSettle(const Duration(seconds: 30));

    expect(find.text('Businesses'), findsOneWidget);

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('login_and_business_list');
  });
}
