import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_screen.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';

/// S-025 AC8 / S-024 AC9-AC10: the app-bar notifications and favorites entry
/// points are only reachable for the roles allowed to use them, and are
/// entirely absent (not just disabled) otherwise.

UserResponse _user(UserRole role) => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = role
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> searchBusinesses({int page = 1, int pageSize = 20}) async => [];
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(ApiClient());

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async => [];
}

Future<ProviderContainer> _pumpBusinessList(WidgetTester tester, {required UserResponse? user}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
      notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: BusinessListScreen())),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('logged out: no notifications icon and no favorites icon, only Sign in', (tester) async {
    final container = await _pumpBusinessList(tester, user: null);

    expect(find.byKey(const Key('notificationsButton')), findsNothing);
    expect(find.byKey(const Key('favoritesButton')), findsNothing);
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsNothing);

    container.dispose();
  });

  testWidgets('logged in as customer: shows notifications and favorites entry points', (tester) async {
    final container = await _pumpBusinessList(tester, user: _user(UserRole.customer));

    expect(find.byKey(const Key('notificationsButton')), findsOneWidget);
    expect(find.byKey(const Key('favoritesButton')), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(find.byKey(const Key('signInButton')), findsNothing);

    container.dispose();
  });

  testWidgets('logged in as merchant: shows notifications but not favorites (customer-only)', (tester) async {
    final container = await _pumpBusinessList(tester, user: _user(UserRole.merchant));

    expect(find.byKey(const Key('notificationsButton')), findsOneWidget);
    expect(find.byKey(const Key('favoritesButton')), findsNothing);

    container.dispose();
  });
}
