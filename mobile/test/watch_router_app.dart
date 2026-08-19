import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_mobile/router.dart';

/// Tests must [watch] [routerProvider]: S-103 rebuilds [GoRouter] when session/role
/// changes so guest trees omit Favorites. A one-shot `container.read` sticks on
/// the guest router after login.
class WatchRouterApp extends ConsumerWidget {
  const WatchRouterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
