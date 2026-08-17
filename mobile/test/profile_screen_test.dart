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
  NationalIdType? nationalIdType,
  String? nationalIdNumber,
}) =>
    UserResponse((b) => b
      ..id = 'user-1'
      ..email = email
      ..fullName = name
      ..role = role
      ..isActive = true
      ..phone = '555-0100'
      ..nationalIdType = nationalIdType
      ..nationalIdNumber = nationalIdNumber
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
      if (payload.nationalIdType != null) b.nationalIdType = payload.nationalIdType;
      if (payload.nationalIdNumber != null) b.nationalIdNumber = payload.nationalIdNumber;
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

  // --- S-056 (M-73): National ID parity fix -----------------------------

  testWidgets('AC1: ID type dropdown offers Select type / PAN / Aadhaar / Other national ID', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    await tester.tap(find.byKey(const Key('nationalIdTypeDropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Select type'), findsWidgets);
    expect(find.text('PAN (India)'), findsWidgets);
    expect(find.text('Aadhaar (India)'), findsWidgets);
    expect(find.text('Other national ID'), findsWidgets);

    result.container.dispose();
  });

  testWidgets('AC2: selecting Aadhaar and saving persists nationalIdType as aadhaar', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    await tester.tap(find.byKey(const Key('nationalIdTypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aadhaar (India)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nationalIdNumberField')), '1234 5678 9012');
    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();

    expect(result.auth.lastPayload?.nationalIdType, NationalIdType.aadhaar);
    expect(result.auth.lastPayload?.nationalIdNumber, '1234 5678 9012');
    expect(find.byKey(const Key('profileSuccess')), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC2: Aadhaar is re-hydrated (shown selected) the next time the profile screen loads', (tester) async {
    final result = await _pumpProfile(
      tester,
      user: _user(nationalIdType: NationalIdType.aadhaar, nationalIdNumber: '1234 5678 9012'),
    );

    // Dropdown closed: only the currently-selected value's text is rendered.
    expect(find.text('Aadhaar (India)'), findsOneWidget);
    expect(find.text('1234 5678 9012'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('AC3: merchant sees the merchant-specific helper copy (verbatim)', (tester) async {
    final result = await _pumpProfile(tester, user: _user(role: UserRole.merchant));

    expect(
      find.text(
        'Required for merchants before you can submit a listing. Stored for your account — not verified as government KYC.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Optional. Stored for your account only'), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC4: customer and admin see the non-merchant helper copy (verbatim)', (tester) async {
    for (final role in [UserRole.customer, UserRole.admin]) {
      final result = await _pumpProfile(tester, user: _user(role: role));
      expect(
        find.text('Optional. Stored for your account only — not verified as KYC in this version.'),
        findsOneWidget,
      );
      expect(find.textContaining('Required for merchants'), findsNothing);
      result.container.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
