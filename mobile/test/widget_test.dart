import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/auth_repository.dart';
import 'package:merchanthub_mobile/features/auth/login_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient());

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<LoginResult> login({required String email, required String password}) async {
    return LoginResult((b) => b
      ..mfaRequired = true
      ..mfaToken = 'fake-mfa-token');
  }

  @override
  Future<UserResponse> totpVerify({required String mfaToken, required String code}) async {
    return UserResponse((b) => b
      ..id = 'fake-id'
      ..email = 'test@example.com'
      ..fullName = 'Test User'
      ..role = UserRole.customer
      ..isActive = true
      ..createdAt = DateTime(2026));
  }

  @override
  Future<String> fetchGoogleClientId() async => '';
}

void main() {
  testWidgets('LoginScreen submits credentials and updates auth state', (tester) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(_FakeAuthRepository())],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign in'), findsWidgets);

    await tester.enterText(find.byKey(const Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    final submit = find.byKey(const Key('submitButton'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mfaCodeField')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('mfaCodeField')), '123456');
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).value?.fullName, 'Test User');
  });
}
