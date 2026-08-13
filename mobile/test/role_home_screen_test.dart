import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/account/role_home_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';

UserResponse _merchant() => UserResponse((b) => b
  ..id = 'm-1'
  ..email = 'merchant@example.com'
  ..fullName = 'Mina Merchant'
  ..role = UserRole.merchant
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _merchant();
}

void main() {
  testWidgets('merchant home is a web-dashboard placeholder with no AI insights UI', (tester) async {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_FakeAuthController.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoleHomeScreen.merchant()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Merchant'), findsOneWidget);
    expect(find.textContaining('on the web for now'), findsOneWidget);
    expect(find.textContaining('suggestion'), findsNothing);
    expect(find.textContaining('AI:'), findsNothing);
    expect(find.byKey(const Key('roleHomeExploreButton')), findsOneWidget);
  });

  testWidgets('admin home is a web-tools placeholder with no AI insights UI', (tester) async {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_FakeAuthController.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoleHomeScreen.admin()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.textContaining('on the web for now'), findsOneWidget);
    expect(find.textContaining('suggestion'), findsNothing);
    expect(find.textContaining('AI:'), findsNothing);
  });
}
