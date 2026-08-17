import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/theme/theme_preference_storage.dart';
import 'features/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // S-054 AC 1: read the persisted theme before the first frame so the app
  // never repaints from light to dark after launch.
  final initialThemeMode = await ThemePreferenceStorage().read();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => ThemeModeController(initialThemeMode)),
      ],
      child: const MerchantHubApp(),
    ),
  );
}
