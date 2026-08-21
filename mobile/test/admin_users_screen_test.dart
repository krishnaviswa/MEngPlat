import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_providers.dart';
import 'package:merchanthub_mobile/features/admin/admin_repository.dart';
import 'package:merchanthub_mobile/features/admin/admin_users_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';

/// S-061 (M-64) AC8/AC9: user suspend/reactivate admin surface.

UserResponse _user({
  String id = 'u-1',
  String email = 'user@example.com',
  UserRole role = UserRole.customer,
  bool isActive = true,
}) {
  return UserResponse((b) => b
    ..id = id
    ..email = email
    ..fullName = 'Test User $id'
    ..role = role
    ..isActive = isActive
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.admin);

  final UserResponse admin;

  @override
  Future<UserResponse?> build() async => admin;
}

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({this.users = const []}) : super(ApiClient());

  List<UserResponse> users;
  final suspended = <String>[];
  final reactivated = <String>[];

  String? lastQ;

  @override
  Future<List<UserResponse>> listUsers({String? q}) async {
    lastQ = q;
    return users;
  }

  @override
  Future<UserResponse> suspendUser(String userId) async {
    suspended.add(userId);
    users = [
      for (final u in users)
        if (u.id == userId) u.rebuild((b) => b.isActive = false) else u,
    ];
    return users.firstWhere((u) => u.id == userId);
  }

  @override
  Future<UserResponse> reactivateUser(String userId) async {
    reactivated.add(userId);
    users = [
      for (final u in users)
        if (u.id == userId) u.rebuild((b) => b.isActive = true) else u,
    ];
    return users.firstWhere((u) => u.id == userId);
  }
}

Future<_FakeAdminRepository> _pumpScreen(
  WidgetTester tester, {
  required UserResponse admin,
  List<UserResponse> users = const [],
}) async {
  final repo = _FakeAdminRepository(users: users);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(admin)),
      adminRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: AdminUsersScreen())),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  final admin = _user(id: 'admin-1', email: 'admin@example.com', role: UserRole.admin);

  testWidgets('AC8: suspend button sets is_active false via the repository', (tester) async {
    final repo = await _pumpScreen(
      tester,
      admin: admin,
      users: [admin, _user(id: 'cust-1', role: UserRole.customer, isActive: true)],
    );

    expect(find.byKey(const Key('suspendUser-cust-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('suspendUser-cust-1')));
    await tester.pumpAndSettle();

    expect(repo.suspended, ['cust-1']);
    expect(find.byKey(const Key('reactivateUser-cust-1')), findsOneWidget);
  });

  testWidgets('AC8: reactivate button sets is_active true via the repository', (tester) async {
    final repo = await _pumpScreen(
      tester,
      admin: admin,
      users: [admin, _user(id: 'merch-1', role: UserRole.merchant, isActive: false)],
    );

    expect(find.byKey(const Key('reactivateUser-merch-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reactivateUser-merch-1')));
    await tester.pumpAndSettle();

    expect(repo.reactivated, ['merch-1']);
    expect(find.byKey(const Key('suspendUser-merch-1')), findsOneWidget);
  });

  testWidgets('AC9: suspend/reactivate controls are hidden entirely for admin rows and the signed-in admin\'s own row',
      (tester) async {
    await _pumpScreen(
      tester,
      admin: admin,
      users: [
        admin,
        _user(id: 'other-admin', role: UserRole.admin, isActive: true),
        _user(id: 'cust-1', role: UserRole.customer, isActive: true),
      ],
    );

    // The signed-in admin's own row and the other admin row show no controls.
    expect(find.byKey(const Key('suspendUser-admin-1')), findsNothing);
    expect(find.byKey(const Key('reactivateUser-admin-1')), findsNothing);
    expect(find.byKey(const Key('suspendUser-other-admin')), findsNothing);
    expect(find.byKey(const Key('reactivateUser-other-admin')), findsNothing);
    // Ordinary rows still show the control.
    expect(find.byKey(const Key('suspendUser-cust-1')), findsOneWidget);
  });

  testWidgets('S-115: retain-records copy is visible and there is no delete control', (tester) async {
    await _pumpScreen(
      tester,
      admin: admin,
      users: [_user(id: 'cust-1', role: UserRole.customer, isActive: true)],
    );

    expect(find.byKey(const Key('adminUsersRetainCopy')), findsOneWidget);
    expect(
      find.text('Suspend blocks sign-in; reviews and account records are kept. There is no delete.'),
      findsOneWidget,
    );
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('empty list shows a plain empty state, not an error', (tester) async {
    await _pumpScreen(tester, admin: admin, users: const []);
    expect(find.text('No users'), findsOneWidget);
    expect(find.byKey(const Key('adminUsersScreen')), findsOneWidget);
  });

  testWidgets('S-093: role chips render and search debounce calls listUsers with q', (tester) async {
    final repo = await _pumpScreen(
      tester,
      admin: admin,
      users: [_user(id: 'cust-1', role: UserRole.customer)],
    );
    expect(find.byKey(const Key('roleChip-cust-1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('adminUsersSearchField')), 'ada');
    await tester.pump(const Duration(milliseconds: 350));
    expect(repo.lastQ, 'ada');
  });
}
