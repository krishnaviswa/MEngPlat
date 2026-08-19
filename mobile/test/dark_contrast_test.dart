import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/account/profile_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/auth/login_screen.dart';
import 'package:merchanthub_mobile/ui/theme.dart';
import 'package:merchanthub_mobile/ui/tokens.dart';
import 'package:merchanthub_mobile/ui/widgets.dart';

UserResponse _user() => UserResponse((b) => b
  ..id = 'user-1'
  ..email = 'casey@example.com'
  ..fullName = 'Casey Customer'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);

  final UserResponse _user;

  @override
  Future<UserResponse?> build() async => _user;
}

void main() {
  testWidgets('MhStatTile dark ink is not light-mode slate on a dark surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MhTheme.dark(),
        home: const Scaffold(
          body: MhStatTile(label: 'Reviews', value: '12'),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Reviews'));
    expect(label.style?.color, MhAccent.sky.inkFor(Brightness.dark));
    expect(label.style?.color, isNot(MhTokens.ink));
    expect(label.style?.color, isNot(MhTokens.brand700));

    final material = tester.widget<Material>(find.descendant(
      of: find.byType(MhStatTile),
      matching: find.byType(Material),
    ).first);
    expect(material.color, MhAccent.sky.washFor(Brightness.dark));
    expect(material.color, isNot(MhTokens.brand100));
  });

  testWidgets('Profile and Login dark theme use inkDark, not light ink', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(() => _FakeAuthController(_user()))],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: MhTheme.dark(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profileContext = tester.element(find.byKey(const Key('profileScreen')));
    expect(Theme.of(profileContext).colorScheme.onSurface, MhTokens.inkDark);
    expect(Theme.of(profileContext).colorScheme.surface, MhTokens.surfaceDark);
    expect(Theme.of(profileContext).colorScheme.onSurface, isNot(MhTokens.ink));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: MhTheme.dark(),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final loginContext = tester.element(find.byKey(const Key('emailField')));
    expect(Theme.of(loginContext).colorScheme.onSurface, MhTokens.inkDark);
    expect(Theme.of(loginContext).textTheme.bodyMedium?.color, MhTokens.inkDark);
  });
}
