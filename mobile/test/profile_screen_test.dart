import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/account/profile_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';

UserResponse _user({
  UserRole role = UserRole.customer,
  String name = 'Casey Customer',
  String email = 'casey@example.com',
}) =>
    UserResponse((b) => b
      ..id = 'user-1'
      ..email = email
      ..fullName = name
      ..role = role
      ..isActive = true
      ..phone = '555-0100'
      ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user, {this.failSave = false});

  UserResponse _user;
  final bool failSave;
  UserProfileUpdate? lastPayload;

  @override
  Future<UserResponse?> build() async => _user;

  @override
  Future<UserResponse> updateProfile(UserProfileUpdate payload) async {
    lastPayload = payload;
    if (failSave) throw ApiException('Update failed');
    _user = _user.rebuild((b) {
      if (payload.fullName != null) b.fullName = payload.fullName;
      if (payload.phone != null) b.phone = payload.phone;
    });
    state = AsyncValue.data(_user);
    return _user;
  }
}

Future<({ProviderContainer container, _FakeAuthController auth})> _pumpProfile(
  WidgetTester tester, {
  required UserResponse user,
  bool failSave = false,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController(user, failSave: failSave);
  final container = ProviderContainer(
    overrides: [authControllerProvider.overrideWith(() => auth)],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, auth: auth);
}

void main() {
  testWidgets('AC13/AC17: profile is an edit form with read-only email and role', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    expect(find.byKey(const Key('profileScreen')), findsOneWidget);
    expect(find.byKey(const Key('fullNameField')), findsOneWidget);
    expect(find.byKey(const Key('phoneField')), findsOneWidget);
    expect(find.byKey(const Key('saveProfileButton')), findsOneWidget);
    expect(find.byKey(const Key('profileEmailReadOnly')), findsOneWidget);
    expect(find.byKey(const Key('profileRoleReadOnly')), findsOneWidget);
    expect(find.text('casey@example.com'), findsOneWidget);
    expect(find.text('customer'), findsOneWidget);
    expect(find.text("Email changes aren't supported yet."), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC13: merchant and admin can open the same edit form', (tester) async {
    for (final role in [UserRole.merchant, UserRole.admin]) {
      final result = await _pumpProfile(tester, user: _user(role: role, name: 'Pat', email: 'pat@example.com'));
      expect(find.byKey(const Key('saveProfileButton')), findsOneWidget);
      expect(find.text(role.name), findsOneWidget);
      result.container.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('AC14: save persists display name and shows success', (tester) async {
    final result = await _pumpProfile(tester, user: _user());
    await tester.enterText(find.byKey(const Key('fullNameField')), 'Casey Updated');
    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();

    expect(result.auth.lastPayload?.fullName, 'Casey Updated');
    expect(find.byKey(const Key('profileSuccess')), findsOneWidget);
    expect(find.text('Profile updated.'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC15: save error keeps unsaved input', (tester) async {
    final result = await _pumpProfile(tester, user: _user(), failSave: true);
    await tester.enterText(find.byKey(const Key('fullNameField')), 'Unsaved Name');
    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profileError')), findsOneWidget);
    expect(find.textContaining('Update failed'), findsOneWidget);
    expect(find.text('Unsaved Name'), findsOneWidget);

    result.container.dispose();
  });
}
