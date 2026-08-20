import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/account/profile_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';

UserResponse _user({
  UserRole role = UserRole.customer,
  String name = 'Casey Customer',
  String? email = 'casey@example.com',
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
  Future<UserResponse> updateProfile(
    UserProfileUpdate payload, {
    String? reauthToken,
    String? email,
    bool includeEmail = false,
  }) async {
    lastPayload = payload;
    if (failSave) throw ApiException('Update failed');
    _user = _user.rebuild((b) {
      if (payload.fullName != null) b.fullName = payload.fullName;
      if (payload.phone != null) b.phone = payload.phone;
      if (payload.nationalIdType != null) b.nationalIdType = payload.nationalIdType;
      if (payload.nationalIdNumber != null) b.nationalIdNumber = payload.nationalIdNumber;
      if (includeEmail) b.email = email;
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
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController(user, failSave: failSave);
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      googleSignInClientProvider.overrideWith((ref) async => const UnconfiguredGoogleSignInClient()),
    ],
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
  testWidgets('AC13/AC17: profile is an edit form with editable email and a role chip', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    expect(find.byKey(const Key('profileScreen')), findsOneWidget);
    expect(find.byKey(const Key('fullNameField')), findsOneWidget);
    expect(find.byKey(const Key('phoneField')), findsOneWidget);
    expect(find.byKey(const Key('saveProfileButton')), findsOneWidget);
    expect(find.byKey(const Key('profileEmailReadOnly')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: find.byKey(const Key('profileEmailReadOnly')), matching: find.byType(TextField)),
          )
          .readOnly,
      isFalse,
    );
    expect(find.byKey(const Key('profileRoleReadOnly')), findsOneWidget);
    expect(find.text('casey@example.com'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('customer'), findsNothing);
    expect(find.text("Email changes aren't supported yet."), findsNothing);

    result.container.dispose();
  });

  testWidgets('blank email stays empty — no "No email on file" placeholder', (tester) async {
    final result = await _pumpProfile(tester, user: _user(email: null));

    expect(find.text('No email on file'), findsNothing);
    final emailField = tester.widget<TextFormField>(find.byKey(const Key('profileEmailReadOnly')));
    expect(emailField.controller?.text, '');
    expect(find.text("Email changes aren't supported yet."), findsNothing);

    result.container.dispose();
  });

  testWidgets('AC13: merchant and admin can open the same edit form', (tester) async {
    for (final role in [UserRole.merchant, UserRole.admin]) {
      final result = await _pumpProfile(tester, user: _user(role: role, name: 'Pat', email: 'pat@example.com'));
      expect(find.byKey(const Key('saveProfileButton')), findsOneWidget);
      expect(find.text(role == UserRole.merchant ? 'Merchant' : 'Admin'), findsOneWidget);
      expect(find.text(role.name), findsNothing);
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
        'Required before listing. Changing phone or ID asks you to confirm with password, SMS, authenticator, or Google.',
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

  testWidgets('S-095: Change photo control exists and Avatar URL field is gone', (tester) async {
    final result = await _pumpProfile(tester, user: _user());
    expect(find.byKey(const Key('avatarUrlField')), findsNothing);
    expect(find.byKey(const Key('changeAvatarButton')), findsOneWidget);
    result.container.dispose();
  });

  testWidgets('S-107: role chip uses a friendly label and scare copy is gone', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    expect(find.byKey(const Key('profileRoleReadOnly')), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('customer'), findsNothing);
    expect(find.textContaining('Authenticator setup is required the next time you sign in'), findsNothing);
    expect(find.text('You can sign in with password, phone, or an authenticator app.'), findsOneWidget);

    result.container.dispose();
  });

  testWidgets('S-107: save without reauth confirm does not call update', (tester) async {
    final result = await _pumpProfile(tester, user: _user());

    await tester.ensureVisible(find.byKey(const Key('profileEmailReadOnly')));
    await tester.enterText(find.byKey(const Key('profileEmailReadOnly')), 'new-casey@example.com');
    await tester.ensureVisible(find.byKey(const Key('saveProfileButton')));
    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reauthPassword')), findsOneWidget);
    expect(find.byKey(const Key('reauthPhone')), findsOneWidget);
    expect(find.byKey(const Key('reauthAuthenticator')), findsOneWidget);
    expect(result.auth.lastPayload, isNull);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(result.auth.lastPayload, isNull);

    result.container.dispose();
  });

  testWidgets('S-114: merchant national ID save asks for reauth', (tester) async {
    final result = await _pumpProfile(tester, user: _user(role: UserRole.merchant, name: 'Mina Merchant'));

    await tester.ensureVisible(find.byKey(const Key('nationalIdTypeDropdown')));
    await tester.tap(find.byKey(const Key('nationalIdTypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PAN (India)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nationalIdNumberField')), 'ABCDE1234F');
    await tester.ensureVisible(find.byKey(const Key('saveProfileButton')));
    await tester.tap(find.byKey(const Key('saveProfileButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reauthPassword')), findsOneWidget);
    expect(result.auth.lastPayload, isNull);

    result.container.dispose();
  });
}
