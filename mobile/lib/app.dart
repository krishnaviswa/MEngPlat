import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/theme/theme_provider.dart';
import 'router.dart';
import 'ui/theme.dart';

class MerchantHubApp extends ConsumerWidget {
  const MerchantHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MerchantHub',
      theme: MhTheme.light(),
      darkTheme: MhTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
