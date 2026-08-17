import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/theme/theme_provider.dart';
import 'package:merchanthub_mobile/features/theme/theme_preference_storage.dart';
import 'package:merchanthub_mobile/features/theme/theme_toggle_button.dart';

/// S-054 AC3/AC4/AC8: the theme toggle is visible and tappable, persists an
/// explicit choice via [ThemePreferenceStorage], and applies app-wide via
/// [themeModeProvider] -- without exercising the real `shared_preferences`
/// platform channel (a fake storage stands in, mirroring
/// `favorite_toggle_button_test.dart`'s fake-repository pattern).

class _FakeThemePreferenceStorage implements ThemePreferenceStorage {
  final List<ThemeMode> writes = [];

  @override
  Future<ThemeMode> read() async => ThemeMode.system;

  @override
  Future<void> write(ThemeMode mode) async {
    writes.add(mode);
  }
}

Future<_FakeThemePreferenceStorage> _pumpApp(WidgetTester tester) async {
  final fakeStorage = _FakeThemePreferenceStorage();
  final container = ProviderContainer(
    overrides: [themePreferenceStorageProvider.overrideWithValue(fakeStorage)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          return MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            darkTheme: ThemeData(brightness: Brightness.dark),
            themeMode: mode,
            home: Scaffold(
              appBar: AppBar(title: const Text('Test Screen'), actions: const [ThemeToggleButton()]),
              body: const Center(child: Text('body')),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeStorage;
}

Finder _toggleFinder() => find.byKey(const Key('themeToggle'));

void main() {
  testWidgets('AC3: the theme toggle is visible and discoverable in the app bar', (tester) async {
    await _pumpApp(tester);

    expect(_toggleFinder(), findsOneWidget);
  });

  testWidgets('AC4/AC8: selecting Dark applies the theme app-wide and persists the explicit choice', (tester) async {
    final fakeStorage = await _pumpApp(tester);

    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.light);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('themeOptionDark')));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.dark);
    expect(fakeStorage.writes, [ThemeMode.dark]);
  });

  testWidgets('AC4: selecting Light then System round-trips and persists each explicit/implicit choice', (tester) async {
    final fakeStorage = await _pumpApp(tester);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('themeOptionLight')));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.light);

    await tester.tap(_toggleFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('themeOptionSystem')));
    await tester.pumpAndSettle();

    expect(fakeStorage.writes, [ThemeMode.light, ThemeMode.system]);
  });

  testWidgets('AC2: with no explicit choice stored and the OS reporting light, the app renders light',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pumpApp(tester);

    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.light);
  });

  testWidgets('AC5: with no explicit choice stored, a live OS theme change while foregrounded is followed',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pumpApp(tester);
    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('body'))).brightness, Brightness.dark,
        reason: 'ThemeMode.system must track a live OS brightness change without an explicit user choice');
  });
}
