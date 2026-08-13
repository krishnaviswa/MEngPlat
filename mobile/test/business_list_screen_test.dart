import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_screen.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';

/// S-027 AC15: Explore no longer hosts list-only Favorites / Notifications / Logout
/// app-bar actions — those live on the primary shell.

UserResponse _user() => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'user@example.com'
  ..fullName = 'Test User'
  ..role = UserRole.customer
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

Future<ProviderContainer> _pumpBusinessList(WidgetTester tester, {required UserResponse? user}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: BusinessListScreen())),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Explore app bar has no logout, favorites, or notifications actions', (tester) async {
    final loggedIn = await _pumpBusinessList(tester, user: _user());
    expect(find.byKey(const Key('logoutButton')), findsNothing);
    expect(find.byKey(const Key('favoritesButton')), findsNothing);
    expect(find.byKey(const Key('notificationsButton')), findsNothing);
    expect(find.byKey(const Key('signInButton')), findsNothing);
    loggedIn.dispose();

    final guest = await _pumpBusinessList(tester, user: null);
    expect(find.byKey(const Key('logoutButton')), findsNothing);
    expect(find.byKey(const Key('signInButton')), findsNothing);
    guest.dispose();
  });
}
