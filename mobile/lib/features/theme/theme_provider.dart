import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_preference_storage.dart';

final themePreferenceStorageProvider = Provider<ThemePreferenceStorage>(
  (ref) => ThemePreferenceStorage(),
);

/// Drives [MaterialApp.router]'s `themeMode` (S-054 / M-75). `main()` reads
/// the persisted preference before `runApp()` and overrides this provider's
/// initial state so the first frame is already correctly themed -- see the
/// slice's cold-start decision for why that's the Flutter-native equivalent
/// of web's pre-hydration theme script.
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController([this._initial = ThemeMode.system]);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themePreferenceStorageProvider).write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
