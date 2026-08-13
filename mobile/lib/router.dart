import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'features/account/account_screen.dart';
import 'features/account/profile_screen.dart';
import 'features/account/role_home_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/post_login_path.dart';
import 'features/businesses/business_detail_screen.dart';
import 'features/businesses/business_list_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/shell/app_shell.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's [GoRouter],
/// which needs a [Listenable] to know when to re-run its `redirect` callback.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/businesses',
            builder: (context, state) => const BusinessListScreen(),
            routes: [
              // Full-screen over the shell (S-027 AC13).
              GoRoute(
                path: ':slug',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => BusinessDetailScreen(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
            routes: [
              GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
          GoRoute(
            path: '/merchant',
            builder: (context, state) => const RoleHomeScreen.merchant(key: Key('merchantHomeScreen')),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const RoleHomeScreen.admin(key: Key('adminHomeScreen')),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';
      // Public carve-out (ADR-003): business browsing and its reviews are
      // reachable without a session. Shell chrome on `/businesses` is fine
      // for guests; every other shell route stays auth-gated (ADR-005).
      final isPublicBusinessRoute = loc == '/businesses' || loc.startsWith('/businesses/');

      if (!isLoggedIn && !isOnLogin && !isPublicBusinessRoute) return '/login';
      if (isLoggedIn && isOnLogin) return postLoginPath(user.role);

      if (isLoggedIn) {
        if (loc == '/favorites' && user.role != UserRole.customer) return postLoginPath(user.role);
        if (loc == '/merchant' && user.role != UserRole.merchant) return postLoginPath(user.role);
        if (loc == '/admin' && user.role != UserRole.admin) return postLoginPath(user.role);
      }
      return null;
    },
  );
});
