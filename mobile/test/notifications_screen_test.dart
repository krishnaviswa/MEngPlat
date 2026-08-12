import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_screen.dart';

/// S-025 AC2/AC3/AC4/AC5/AC7: the Notifications screen's list rendering
/// (unread vs. read styling), tap-to-mark-read, "Mark all as read", the
/// empty state, and error+Retry.

UserResponse _user() => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

NotificationResponse _notification({required String id, required String title, bool isRead = false}) {
  return NotificationResponse((b) => b
    ..id = id
    ..type = 'REVIEW'
    ..title = title
    ..message = 'Someone left a new review.'
    ..isRead = isRead
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _user();
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository({List<NotificationResponse> notifications = const [], this.listError})
      : _notifications = [...notifications],
        super(ApiClient());

  final List<NotificationResponse> _notifications;
  final Object? listError;
  int markAllReadCalls = 0;
  int listCalls = 0;

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async {
    listCalls++;
    final error = listError;
    if (error != null) throw error;
    if (unreadOnly) return _notifications.where((n) => !n.isRead).toList();
    return _notifications;
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) _notifications[index] = _notifications[index].rebuild((b) => b..isRead = true);
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].rebuild((b) => b..isRead = true);
    }
  }
}

/// Returns the [ProviderContainer] so callers can [ProviderContainer.dispose]
/// it explicitly at the end of the test body. `unreadCountProvider` is
/// deliberately non-`.autoDispose` (Architect spec, so the badge survives
/// navigation) and owns a real `Timer.periodic` -- disposing only via
/// `addTearDown` runs too late for flutter_test's pending-timer invariant
/// check, so every test below cancels it inline before returning.
/// The `(container, repository)` pair -- the repository lets callers assert
/// call counts (e.g. pull-to-refresh) alongside the container's provider state.
Future<(ProviderContainer, _FakeNotificationsRepository)> _pumpNotificationsScreen(
  WidgetTester tester, {
  List<NotificationResponse> notifications = const [],
  Object? listError,
}) async {
  final repository = _FakeNotificationsRepository(notifications: notifications, listError: listError);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      notificationsRepositoryProvider.overrideWithValue(repository),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: NotificationsScreen())),
  );
  await tester.pumpAndSettle();
  return (container, repository);
}

void main() {
  testWidgets('AC2: lists notifications with unread items visually distinguished from read ones', (tester) async {
    final (container, _) = await _pumpNotificationsScreen(
      tester,
      notifications: [
        _notification(id: 'n1', title: 'New review posted', isRead: false),
        _notification(id: 'n2', title: 'Older notification', isRead: true),
      ],
    );

    expect(find.text('New review posted'), findsOneWidget);
    expect(find.text('Older notification'), findsOneWidget);

    final unreadTitle = tester.widget<Text>(find.text('New review posted'));
    final readTitle = tester.widget<Text>(find.text('Older notification'));
    expect(unreadTitle.style?.fontWeight, FontWeight.bold);
    expect(readTitle.style?.fontWeight, isNot(FontWeight.bold));

    container.dispose();
  });

  testWidgets('AC3: tapping an unread notification marks it read, clears its styling, and decrements the badge', (
    tester,
  ) async {
    final (container, _) = await _pumpNotificationsScreen(
      tester,
      notifications: [_notification(id: 'n1', title: 'New review posted')],
    );

    expect(tester.widget<Text>(find.text('New review posted')).style?.fontWeight, FontWeight.bold);
    expect(container.read(unreadCountProvider), 1, reason: 'badge should reflect the one unread notification');

    await tester.tap(find.byKey(const Key('notification-n1')));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('New review posted')).style?.fontWeight, isNot(FontWeight.bold));
    expect(
      container.read(unreadCountProvider),
      0,
      reason: 'marking the notification read must decrement the shared unreadCountProvider, not just the local list',
    );

    container.dispose();
  });

  testWidgets('AC4: "Mark all as read" clears unread styling from every item and zeroes the badge', (tester) async {
    final (container, _) = await _pumpNotificationsScreen(
      tester,
      notifications: [
        _notification(id: 'n1', title: 'First'),
        _notification(id: 'n2', title: 'Second'),
      ],
    );
    expect(container.read(unreadCountProvider), 2);

    await tester.tap(find.byKey(const Key('markAllReadButton')));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('First')).style?.fontWeight, isNot(FontWeight.bold));
    expect(tester.widget<Text>(find.text('Second')).style?.fontWeight, isNot(FontWeight.bold));
    expect(
      container.read(unreadCountProvider),
      0,
      reason: '"Mark all as read" must zero the shared unreadCountProvider immediately',
    );

    container.dispose();
  });

  testWidgets('"Mark all as read" is disabled when there is nothing unread', (tester) async {
    final (container, _) = await _pumpNotificationsScreen(
      tester,
      notifications: [_notification(id: 'n1', title: 'Already read', isRead: true)],
    );

    final button = tester.widget<TextButton>(find.byKey(const Key('markAllReadButton')));
    expect(button.onPressed, isNull);

    container.dispose();
  });

  testWidgets('AC5: shows an empty-state message when there are zero notifications', (tester) async {
    final (container, _) = await _pumpNotificationsScreen(tester, notifications: const []);

    expect(find.text('No notifications yet'), findsOneWidget);

    container.dispose();
  });

  testWidgets('AC6: pull-to-refresh re-fetches the notifications list', (tester) async {
    final (container, repository) = await _pumpNotificationsScreen(
      tester,
      notifications: [_notification(id: 'n1', title: 'New review posted')],
    );
    final callsAfterInitialLoad = repository.listCalls;

    // Invoke the RefreshIndicator's onRefresh callback directly rather than
    // via RefreshIndicatorState.show()/a drag gesture: the latter drives a
    // real AnimationController that can hang a widget test indefinitely if
    // awaited without precisely-interleaved pump() calls (see
    // TR-S-023-mobile-reviews.md for the full account of this deadlock).
    final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();
    await tester.pump();

    expect(
      repository.listCalls,
      greaterThan(callsAfterInitialLoad),
      reason: 'pull-to-refresh must trigger a refetch of the notifications list',
    );

    container.dispose();
  });

  testWidgets('AC7: shows an inline error with a Retry action when the initial load fails', (tester) async {
    final (container, _) = await _pumpNotificationsScreen(tester, listError: ApiException('Network error'));

    expect(find.text('Network error'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

    container.dispose();
  });
}
