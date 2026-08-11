import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:merchanthub_mobile/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and view business list', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MerchantHubApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'customer@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'customer123');
    await tester.tap(find.byKey(const Key('submitButton')));

    // Backend round trips (login -> me -> search) can take several seconds
    // against a freshly booted CI backend; give it real headroom.
    await tester.pumpAndSettle(const Duration(seconds: 30));

    expect(find.text('Businesses'), findsOneWidget);

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('login_and_business_list');
  });
}
