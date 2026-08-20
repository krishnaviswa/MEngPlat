import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'features/account/account_screen.dart';
import 'features/account/profile_screen.dart';
import 'features/admin/admin_business_reports_screen.dart';
import 'features/admin/admin_businesses_screen.dart';
import 'features/admin/admin_categories_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/admin/admin_reviews_screen.dart';
import 'features/admin/admin_support_queue_screen.dart';
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
import 'features/support/support_screen.dart';
import 'features/support/support_ticket_detail_screen.dart';
import 'ui/nav.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's [GoRouter],
/// which needs a [Listenable] to know when to re-run its `redirect` callback.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

String _sessionKey(UserResponse? user) {
  if (user == null) return 'guest';
  return '${user.role.name}:${user.id}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  // Rebuild the route tree when role/session changes so guest never mounts
  // Favorites/Notifications (ADR-005 / S-103).
  ref.watch(authControllerProvider.select((state) => _sessionKey(state.valueOrNull)));
  final user = ref.read(authControllerProvider).valueOrNull;

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
      GoRoute(
        path: '/collect/:slug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CollectReviewScreen(slug: state.pathParameters['slug']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: _branchesFor(user, rootNavigatorKey),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) return null;

      final session = authState.valueOrNull;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';
      final isOnRegister = loc == '/register';
      final isOnForgotPassword = loc == '/forgot-password';
      final isPublicBusinessRoute = loc == '/businesses' || loc.startsWith('/businesses/');
      final isPublicHomeRoute = loc == '/home';
      final isPublicSupportRoute = loc == '/support';
      final isPublicCollectRoute = loc.startsWith('/collect/');

      if (!isLoggedIn &&
          !isOnLogin &&
          !isOnRegister &&
          !isOnForgotPassword &&
          !isPublicBusinessRoute &&
          !isPublicHomeRoute &&
          !isPublicSupportRoute &&
          !isPublicCollectRoute) {
        return '/login';
      }
      if (isLoggedIn && (isOnLogin || isOnRegister)) {
        final next = state.uri.queryParameters['next'];
        if (next != null && next.startsWith('/collect/')) return next;
        return postLoginPath(session.role);
      }

      if (isLoggedIn) {
        if (loc == '/favorites' && session.role != UserRole.customer) return postLoginPath(session.role);
        if (loc.startsWith('/merchant') && session.role != UserRole.merchant) return postLoginPath(session.role);
        if (loc.startsWith('/admin') && session.role != UserRole.admin) return postLoginPath(session.role);
      }
      return null;
    },
  );
});

List<StatefulShellBranch> _branchesFor(UserResponse? user, GlobalKey<NavigatorState> rootNavigatorKey) {
  final explore = StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/businesses',
        builder: (context, state) => const BusinessListScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) => mhSlidePage(
              key: state.pageKey,
              child: BusinessDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) => mhSlidePage(
          key: state.pageKey,
          child: const SupportScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => mhSlidePage(
              key: state.pageKey,
              child: SupportTicketDetailScreen(ticketId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );

  final notifications = StatefulShellBranch(
    routes: [
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
  );

  final account = StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            pageBuilder: (context, state) => mhSlidePage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  if (user == null) {
    return [
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        ],
      ),
      explore,
    ];
  }

  final home = StatefulShellBranch(
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );

  if (user.role == UserRole.merchant) {
    return [
      home,
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/merchant',
            builder: (context, state) => const MerchantDashboardScreen(),
            routes: [
              GoRoute(
                path: 'insights',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const MerchantDashboardScreen(section: MerchantSection.insights),
                ),
              ),
              GoRoute(
                path: 'reviews',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const MerchantDashboardScreen(section: MerchantSection.reviews),
                ),
              ),
              GoRoute(
                path: 'grow',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const MerchantDashboardScreen(section: MerchantSection.grow),
                ),
              ),
              GoRoute(
                path: 'businesses/new',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const BusinessEditorScreen(),
                ),
              ),
              GoRoute(
                path: 'businesses/:id/edit',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: BusinessEditorScreen(businessId: state.pathParameters['id']),
                ),
              ),
            ],
          ),
        ],
      ),
      explore,
      notifications,
      account,
    ];
  }

  if (user.role == UserRole.admin) {
    return [
      home,
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminHomeScreen(),
            routes: [
              GoRoute(
                path: 'businesses',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminBusinessesScreen(),
                ),
              ),
              GoRoute(
                path: 'reviews',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminReviewsScreen(),
                ),
              ),
              GoRoute(
                path: 'categories',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminCategoriesScreen(),
                ),
              ),
              GoRoute(
                path: 'users',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminUsersScreen(),
                ),
              ),
              GoRoute(
                path: 'whatsapp',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminWhatsAppQueueScreen(),
                ),
              ),
              GoRoute(
                path: 'support',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminSupportQueueScreen(),
                ),
              ),
              GoRoute(
                path: 'business-reports',
                pageBuilder: (context, state) => mhSlidePage(
                  key: state.pageKey,
                  child: const AdminBusinessReportsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      explore,
      notifications,
      account,
    ];
  }

  return [
    home,
    explore,
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      ],
    ),
    notifications,
    account,
  ];
}
