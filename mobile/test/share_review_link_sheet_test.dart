import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_mobile/core/config/app_config.dart';
import 'package:merchanthub_mobile/features/merchant/share_review_link_sheet.dart';

/// S-059 (M-71 parity) AC1: the merchant "Share review link" QR/share sheet.
/// One https collect URL (same as web). In-app collect is the Open button.

Future<void> _pumpSheet(WidgetTester tester, {required String slug}) async {
  final router = GoRouter(
    initialLocation: '/merchant',
    routes: [
      GoRoute(
        path: '/merchant',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ShareReviewLinkSheet.show(
                context,
                businessName: "Joe's Diner",
                slug: slug,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/collect/:slug',
        builder: (context, state) => Scaffold(
          body: Text('COLLECT_SCREEN ${state.pathParameters['slug']}'),
        ),
      ),
    ],
  );

  // Widen the test surface -- the sheet's QR code + link + two buttons
  // overflow the default 800x600 surface height, which both trips a
  // RenderFlex-overflow assertion and leaves "Preview in app" off-screen for
  // tap() (same fix as S-058's Tester applied elsewhere for this class of
  // test-environment-only overflow).
  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC1: shows a QR encoding the website collect URL', (
    tester,
  ) async {
    await _pumpSheet(tester, slug: 'joes-diner');

    expect(find.byKey(const Key('shareReviewLinkQr')), findsOneWidget);
    expect(
      find.text('${AppConfig.webBaseUrl}/collect/joes-diner'),
      findsOneWidget,
    );
    expect(find.textContaining('merchanthub://'), findsNothing);
    expect(find.text("Joe's Diner"), findsOneWidget);
  });

  testWidgets(
    'AC1: a "Share link" action is present to hand the link to the device share sheet',
    (tester) async {
      await _pumpSheet(tester, slug: 'joes-diner');

      expect(
        find.byKey(const Key('shareReviewLinkSheetShareButton')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'S-120: a "Share QR to print" action is present alongside the text-link share button',
    (tester) async {
      await _pumpSheet(tester, slug: 'joes-diner');

      expect(
        find.byKey(const Key('shareReviewLinkQrImageButton')),
        findsOneWidget,
      );
      expect(find.text('Share QR to print'), findsOneWidget);
    },
  );

  // S-120 AC5: actually tapping through to a verified `SharePlus.instance.share(...)`
  // call is not exercised here. Unlike S-060's text-only CSV-export share
  // (which cleanly fakes via `SharePlatform.instance`, see
  // `merchant_dashboard_screen_test.dart`), `share_plus`'s file-sharing path
  // calls its concrete `MethodChannelShare` directly rather than through that
  // mockable seam, so faking `SharePlatform.instance` here does not intercept
  // it -- the real method channel is invoked and hangs indefinitely with no
  // native responder in a `flutter_test` widget test. Verifying the actual
  // native share call for a file requires `integration_test` on a real
  // device/emulator (this repo keeps emulator-level checks CI-only, per
  // `CLAUDE.md` non-negotiable 8) -- tracked as a follow-up, not a gap in the
  // implementation itself. This suite covers everything reachable in a
  // widget test: the button exists, and (above) is wired to the correct key.

  testWidgets('"Open review form in this app" opens /collect/:slug', (
    tester,
  ) async {
    await _pumpSheet(tester, slug: 'joes-diner');

    await tester.tap(find.byKey(const Key('previewReviewLinkInAppButton')));
    await tester.pumpAndSettle();

    expect(find.text('COLLECT_SCREEN joes-diner'), findsOneWidget);
  });
}
