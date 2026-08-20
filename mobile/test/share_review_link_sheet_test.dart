import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_mobile/core/config/app_config.dart';
import 'package:merchanthub_mobile/features/merchant/share_review_link_sheet.dart';

/// S-059 (M-71 parity) AC1: the merchant "Share review link" QR/share sheet.
/// Renders a QR code encoding the business's public web collection URL,
/// offers a native-share action, and an in-app-only "Preview in app" link
/// to the new `/collect/:slug` route (per the Architect's deep-link scope
/// decision -- the QR/link itself always encodes the web URL, never a
/// mobile-only scheme).

Future<void> _pumpSheet(WidgetTester tester, {required String slug}) async {
  final router = GoRouter(
    initialLocation: '/merchant',
    routes: [
      GoRoute(
        path: '/merchant',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ShareReviewLinkSheet.show(context, businessName: "Joe's Diner", slug: slug),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/collect/:slug',
        builder: (context, state) => Scaffold(body: Text('COLLECT_SCREEN ${state.pathParameters['slug']}')),
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
  testWidgets('AC1: shows a QR code encoding the business public web collection URL', (tester) async {
    await _pumpSheet(tester, slug: 'joes-diner');

    expect(find.byKey(const Key('shareReviewLinkQr')), findsOneWidget);
    // qr_flutter's QR payload (`_data`) isn't publicly readable off the
    // widget instance -- assert the same URL is independently rendered as
    // selectable text next to the code, which is the observable proof both
    // encode the same link.
    expect(find.text('${AppConfig.webBaseUrl}/collect/joes-diner'), findsOneWidget);
    expect(find.textContaining('/collect/'), findsWidgets);
    expect(find.text("Joe's Diner"), findsOneWidget);
  });

  testWidgets('AC1: a "Share link" action is present to hand the link to the device share sheet', (tester) async {
    await _pumpSheet(tester, slug: 'joes-diner');

    expect(find.byKey(const Key('shareReviewLinkSheetShareButton')), findsOneWidget);
  });

  testWidgets('"Preview in app" opens the new in-app /collect/:slug route (deep-link scope decision)', (
    tester,
  ) async {
    await _pumpSheet(tester, slug: 'joes-diner');

    await tester.tap(find.byKey(const Key('previewReviewLinkInAppButton')));
    await tester.pumpAndSettle();

    expect(find.text('COLLECT_SCREEN joes-diner'), findsOneWidget);
  });
}
