import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

/// Explicit theme control (S-054 AC 3/4) -- placed in both `AccountScreen`
/// (authenticated) and `BusinessListScreen` (guest-reachable) app bars so
/// every user, signed in or not, can reach it. Both instances read/write the
/// same [themeModeProvider], so toggling from either place is consistent.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      key: const Key('themeToggle'),
      tooltip: 'Theme',
      icon: Icon(_iconFor(mode)),
      onSelected: (next) => ref.read(themeModeProvider.notifier).setThemeMode(next),
      itemBuilder: (context) => const [
        PopupMenuItem(
          key: Key('themeOptionSystem'),
          value: ThemeMode.system,
          child: Text('System'),
        ),
        PopupMenuItem(
          key: Key('themeOptionLight'),
          value: ThemeMode.light,
          child: Text('Light'),
        ),
        PopupMenuItem(
          key: Key('themeOptionDark'),
          value: ThemeMode.dark,
          child: Text('Dark'),
        ),
      ],
    );
  }

  static IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
