import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'features/account/account_screen.dart';
import 'features/account/profile_screen.dart';
import 'features/admin/admin_businesses_screen.dart';
import 'features/admin/admin_categories_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/admin/admin_reviews_screen.dart';
import 'features/admin/admin_users_screen.dart';
import 'features/admin/admin_whatsapp_queue_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/post_login_path.dart';
import 'features/auth/register_screen.dart';
import 'features/businesses/business_detail_screen.dart';
import 'features/businesses/business_list_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/home/home_screen.dart';
import 'features/merchant/business_editor_screen.dart';
import 'features/merchant/merchant_dashboard_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/reviews/collect_review_screen.dart';
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
        builder: (context, state) => LoginScreen(
          registered: state.uri.queryParameters['registered'] == '1',
          prefillEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Public, ungated review-collection landing (S-059/M-71) -- sibling of
      // /login, not nested in the ShellRoute, matching the Architect spec.
      GoRoute(
        path: '/collect/:slug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CollectReviewScreen(slug: state.pathParameters['slug']!),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
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
            builder: (context, state) => const MerchantDashboardScreen(),
            routes: [
              GoRoute(
                path: 'businesses/new',
                builder: (context, state) => const BusinessEditorScreen(),
              ),
              GoRoute(
                path: 'businesses/:id/edit',
                builder: (context, state) => BusinessEditorScreen(businessId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminHomeScreen(),
            routes: [
              GoRoute(path: 'businesses', builder: (context, state) => const AdminBusinessesScreen()),
              GoRoute(path: 'reviews', builder: (context, state) => const AdminReviewsScreen()),
              // M-63/M-64 (S-061): siblings of the two routes above, same
              // free role-gate inheritance from the parent /admin redirect.
              GoRoute(path: 'categories', builder: (context, state) => const AdminCategoriesScreen()),
              GoRoute(path: 'users', builder: (context, state) => const AdminUsersScreen()),
              GoRoute(path: 'whatsapp', builder: (context, state) => const AdminWhatsAppQueueScreen()),
            ],
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
      final isOnRegister = loc == '/register';
      final isOnForgotPassword = loc == '/forgot-password';
      // Public carve-out (ADR-003): business browsing and its reviews are
      // reachable without a session. Shell chrome on `/businesses` is fine
      // for guests; every other shell route stays auth-gated (ADR-005).
      final isPublicBusinessRoute = loc == '/businesses' || loc.startsWith('/businesses/');
      // S-064/Tier 5: marketing home is public, same carve-out shape as
      // Explore. Signed-in shells do not show a Home tab for this route.
      final isPublicHomeRoute = loc == '/home';
      // S-059/M-71: the review-collection landing view is ungated too --
      // only submitting from it (handled in the screen itself) requires a
      // session, same "view is public, action is gated" shape as above.
      final isPublicCollectRoute = loc.startsWith('/collect/');

      if (!isLoggedIn &&
          !isOnLogin &&
          !isOnRegister &&
          !isOnForgotPassword &&
          !isPublicBusinessRoute &&
          !isPublicHomeRoute &&
          !isPublicCollectRoute) {
        return '/login';
      }
      if (isLoggedIn && (isOnLogin || isOnRegister)) {
        // S-059 AC4: after signing in via the /login?next=/collect/{slug}
        // round trip, return to that screen instead of the role's usual
        // post-login destination. Allow-listed to /collect/ so this can't
        // become an open redirect.
        final next = state.uri.queryParameters['next'];
        if (next != null && next.startsWith('/collect/')) return next;
        return postLoginPath(user.role);
      }

      if (isLoggedIn) {
        if (loc == '/favorites' && user.role != UserRole.customer) return postLoginPath(user.role);
        if (loc.startsWith('/merchant') && user.role != UserRole.merchant) return postLoginPath(user.role);
        if (loc.startsWith('/admin') && user.role != UserRole.admin) return postLoginPath(user.role);
      }
      return null;
    },
  );
});
