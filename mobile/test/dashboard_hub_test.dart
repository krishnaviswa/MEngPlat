import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/ui/dashboard_hub.dart';
import 'package:merchanthub_mobile/ui/widgets.dart';

void main() {
  testWidgets('DashboardHubScaffold exposes a shared chrome key', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardHubScaffold(
          title: 'Hub',
          stats: [
            MhStatTile(label: 'Total users', value: '3'),
          ],
          jobs: [],
        ),
      ),
    );
    expect(find.byKey(const Key('dashboardHubScaffold')), findsOneWidget);
    expect(find.text('Hub'), findsOneWidget);
    expect(find.text('Total users'), findsOneWidget);
  });
}
