import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';

/// S-025 AC9: while the app is foregrounded with an active session, the
/// unread badge count is re-fetched every 30s in the background. Also covers
/// AC8's provider-level half: the poll never starts (and the repository is
/// never called) while logged out.

UserResponse _user() => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

NotificationResponse _unread(String id) {
  return NotificationResponse((b) => b
    ..id = id
    ..type = 'REVIEW'
    ..title = 'New review'
    ..message = 'Someone left a new review.'
    ..isRead = false
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository(this.unreadCounts) : super(ApiClient());

  /// One call's worth of unread ids per invocation of `list(unreadOnly: true)`.
  final List<List<String>> unreadCounts;
  int callCount = 0;

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async {
    final index = callCount < unreadCounts.length ? callCount : unreadCounts.length - 1;
    callCount++;
    return unreadCounts[index].map(_unread).toList();
  }
}

void main() {
  testWidgets('polls immediately on first watch, then again every 30s while logged in (AC9)', (tester) async {
    final repository = _FakeNotificationsRepository([
      ['n1', 'n2'], // initial poll on first watch
      ['n1', 'n2', 'n3'], // poll after 30s
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user())),
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) => Text('count:${ref.watch(unreadCountProvider)}')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('count:2'), findsOneWidget);
    expect(repository.callCount, 1);

    await tester.pump(const Duration(seconds: 30));

    expect(find.text('count:3'), findsOneWidget);
    expect(repository.callCount, 2);

    container.dispose();
  });

  testWidgets('a failed poll leaves the last-known count in place instead of crashing/blanking', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user())),
        notificationsRepositoryProvider.overrideWithValue(_ThrowingNotificationsRepository()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) => Text('count:${ref.watch(unreadCountProvider)}')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Starts at 0 (the initial state) and a failed poll must not crash the
    // widget tree or throw an uncaught error.
    expect(find.text('count:0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    container.dispose();
  });

  test('never polls the API while logged out (AC8)', () async {
    final repository = _FakeNotificationsRepository([
      ['should-not-be-fetched'],
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(null)),
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(unreadCountProvider), 0);
    await Future<void>.delayed(Duration.zero);
    expect(repository.callCount, 0);
  });
}

class _ThrowingNotificationsRepository extends NotificationsRepository {
  _ThrowingNotificationsRepository() : super(ApiClient());

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async {
    throw Exception('network error');
  }
}
