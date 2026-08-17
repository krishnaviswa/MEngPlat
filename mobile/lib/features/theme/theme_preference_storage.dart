import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-device dark mode preference (S-054 / M-75). Not a secret, so this
/// deliberately uses `shared_preferences` rather than `TokenStorage`'s
/// `flutter_secure_storage` -- see the slice's technical spec for rationale.
class ThemePreferenceStorage {
  static const _key = 'theme_mode';

  Future<ThemeMode> read() async {
    final prefs = await SharedPreferences.getInstance();
    return _parse(prefs.getString(_key));
  }

  Future<void> write(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _serialize(mode));
  }

  static ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
