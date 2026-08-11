import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/businesses/business_detail_screen.dart';
import 'features/businesses/business_list_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/notifications/notifications_screen.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's [GoRouter],
/// which needs a [Listenable] to know when to re-run its `redirect` callback.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/businesses', builder: (context, state) => const BusinessListScreen()),
      GoRoute(
        path: '/businesses/:slug',
        builder: (context, state) => BusinessDetailScreen(slug: state.pathParameters['slug']!),
      ),
      // S-024/S-025: auth-gated by the default "must be logged in" rule
      // below -- neither is part of ADR-003's public carve-out.
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == '/login';
      // Public carve-out (ADR-003): business browsing and its reviews are
      // reachable without a session, mirroring the web's public
      // /businesses/[slug] page. Every other route keeps the default guard.
      final isPublicBusinessRoute = state.matchedLocation == '/businesses' ||
          state.matchedLocation.startsWith('/businesses/');

      if (!isLoggedIn && !isOnLogin && !isPublicBusinessRoute) return '/login';
      if (isLoggedIn && isOnLogin) return '/businesses';
      return null;
    },
  );
});
