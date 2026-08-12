import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/notifications/notification_badge.dart';

/// S-025 AC1: the unread badge is hidden entirely at count 0, and shows a
/// capped "9+" once the count exceeds single digits, mirroring
/// `NotificationBell.tsx`'s `Badge` usage.

Future<void> _pump(WidgetTester tester, int count) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: NotificationBadge(count: count))));
}

void main() {
  testWidgets('renders nothing when the unread count is 0', (tester) async {
    await _pump(tester, 0);

    expect(find.byKey(const Key('notificationBadge')), findsNothing);
  });

  testWidgets('renders nothing for a negative count (defensive)', (tester) async {
    await _pump(tester, -1);

    expect(find.byKey(const Key('notificationBadge')), findsNothing);
  });

  testWidgets('shows the exact count for single digits', (tester) async {
    await _pump(tester, 3);

    expect(find.byKey(const Key('notificationBadge')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('caps the display at "9+" once the count exceeds 9', (tester) async {
    await _pump(tester, 42);

    expect(find.text('9+'), findsOneWidget);
    expect(find.text('42'), findsNothing);
  });
}
