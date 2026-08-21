import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_button.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';
import 'package:merchanthub_mobile/ui/theme.dart';
import 'package:merchanthub_mobile/ui/tokens.dart';
import 'package:merchanthub_mobile/ui/widgets.dart';

class _ConfiguredGoogleClient implements GoogleSignInClient {
  @override
  bool get isConfigured => true;

  @override
  Future<String?> requestIdToken() async => 'token';
}

Future<void> _pumpButton(WidgetTester tester, {required ThemeData theme}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        googleSignInClientProvider.overrideWith((ref) async => _ConfiguredGoogleClient()),
      ],
      child: MaterialApp(
        theme: theme,
        home: MhCanvas(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GoogleSignInButton(onCredential: (_) async {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('S-116: Google button has a filled surface and strong border in light', (tester) async {
    await _pumpButton(tester, theme: MhTheme.light());

    final button = tester.widget<OutlinedButton>(find.byKey(const Key('googleSignInButton')));
    final bg = button.style?.backgroundColor?.resolve({});
    final side = button.style?.side?.resolve({});
    expect(bg, MhTheme.light().colorScheme.surfaceContainerLowest);
    expect(bg, isNot(Colors.transparent));
    expect(side?.color, isNot(MhTokens.border));
    expect(side?.width, 1.5);
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('S-116: Google button stays filled in dark (not canvas-matching outline)', (tester) async {
    await _pumpButton(tester, theme: MhTheme.dark());

    final button = tester.widget<OutlinedButton>(find.byKey(const Key('googleSignInButton')));
    final bg = button.style?.backgroundColor?.resolve({});
    final side = button.style?.side?.resolve({});
    expect(bg, MhTheme.dark().colorScheme.surfaceContainerLowest);
    expect(side?.color, isNot(MhTokens.borderDark));
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
  });

  testWidgets('S-116: unconfigured Google still hides the button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInClientProvider.overrideWith((ref) async => const UnconfiguredGoogleSignInClient()),
        ],
        child: MaterialApp(
          theme: MhTheme.light(),
          home: GoogleSignInButton(onCredential: (_) async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('googleSignInButton')), findsNothing);
  });
}
