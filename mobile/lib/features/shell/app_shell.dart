import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import '../notifications/notification_badge.dart';
import '../notifications/notifications_providers.dart';

class _Dest {
  const _Dest({
    required this.location,
    required this.destination,
    this.branchIndex,
  });

  final String location;
  final NavigationDestination destination;
  /// Null for destinations that leave the shell (guest Sign in → `/login`).
  final int? branchIndex;
}

Widget _tabIcon(IconData data, Key key) => Icon(data, key: key);

/// Primary chrome (S-027 / ADR-005, S-103): role-aware [NavigationBar] around
/// a [StatefulNavigationShell] so each tab keeps its own back stack.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final unreadCount = user == null ? 0 : ref.watch(unreadCountProvider);
    final location = GoRouterState.of(context).uri.path;
    final destinations = _destinationsFor(user, unreadCount);

    var selectedIndex = destinations.indexWhere(
      (d) => location == d.location || location.startsWith('${d.location}/'),
    );
    if (selectedIndex < 0) {
      selectedIndex = destinations.indexWhere((d) => d.branchIndex == navigationShell.currentIndex);
    }
    if (selectedIndex < 0) selectedIndex = 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onSystemBack(context);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
        key: const Key('primaryNav'),
        selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
        onDestinationSelected: (index) {
          final dest = destinations[index];
          final branch = dest.branchIndex;
          if (branch == null) {
            context.go(dest.location);
            return;
          }
          if (dest.location == '/home') {
            context.go('/home');
            return;
          }
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        destinations: [for (final dest in destinations) dest.destination],
      ),
    ),
    );
  }

  /// Tab-root back goes Home instead of leaving the app (S-116). Nested routes pop first.
  void _onSystemBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    if (path != '/home') {
      context.go('/home');
      return;
    }
    SystemNavigator.pop();
  }

  List<_Dest> _destinationsFor(UserResponse? user, int unreadCount) {
    if (user == null) {
      return [
        _Dest(
          location: '/home',
          branchIndex: 0,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.home_outlined, const Key('homeTab')),
            selectedIcon: _tabIcon(Icons.home, const Key('homeTab')),
            label: 'Home',
          ),
        ),
        _Dest(
          location: '/businesses',
          branchIndex: 1,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.storefront_outlined, const Key('exploreTab')),
            selectedIcon: _tabIcon(Icons.storefront, const Key('exploreTab')),
            label: 'Explore',
          ),
        ),
        _Dest(
          location: '/login',
          destination: NavigationDestination(
            icon: _tabIcon(Icons.login, const Key('signInTab')),
            label: 'Sign in',
          ),
        ),
      ];
    }

    final notificationsIcon = Stack(
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.notifications_outlined, key: Key('notificationsTab')),
        Positioned(right: 0, top: 2, child: NotificationBadge(count: unreadCount)),
      ],
    );
    final notificationsSelected = Stack(
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.notifications, key: Key('notificationsTab')),
        Positioned(right: 0, top: 2, child: NotificationBadge(count: unreadCount)),
      ],
    );
    final notifications = _Dest(
      location: '/notifications',
      branchIndex: 3,
      destination: NavigationDestination(
        icon: notificationsIcon,
        selectedIcon: notificationsSelected,
        label: 'Alerts',
      ),
    );
    final explore = _Dest(
      location: '/businesses',
      branchIndex: 1,
      destination: NavigationDestination(
        icon: _tabIcon(Icons.storefront_outlined, const Key('exploreTab')),
        selectedIcon: _tabIcon(Icons.storefront, const Key('exploreTab')),
        label: 'Explore',
      ),
    );
    final account = _Dest(
      location: '/account',
      branchIndex: 4,
      destination: NavigationDestination(
        icon: _tabIcon(Icons.person_outline, const Key('accountTab')),
        selectedIcon: _tabIcon(Icons.person, const Key('accountTab')),
        label: 'Account',
      ),
    );

    if (user.role == UserRole.merchant) {
      return [
        _Dest(
          location: '/home',
          branchIndex: 0,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.home_outlined, const Key('homeTab')),
            selectedIcon: _tabIcon(Icons.home, const Key('homeTab')),
            label: 'Home',
          ),
        ),
        _Dest(
          location: '/merchant',
          branchIndex: 1,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.storefront_outlined, const Key('merchantHomeTab')),
            selectedIcon: _tabIcon(Icons.store, const Key('merchantHomeTab')),
            label: 'Shop',
          ),
        ),
        _Dest(
          location: '/businesses',
          branchIndex: 2,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.explore_outlined, const Key('exploreTab')),
            selectedIcon: _tabIcon(Icons.explore, const Key('exploreTab')),
            label: 'Explore',
          ),
        ),
        notifications,
        account,
      ];
    }

    if (user.role == UserRole.admin) {
      return [
        _Dest(
          location: '/home',
          branchIndex: 0,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.home_outlined, const Key('homeTab')),
            selectedIcon: _tabIcon(Icons.home, const Key('homeTab')),
            label: 'Home',
          ),
        ),
        _Dest(
          location: '/admin',
          branchIndex: 1,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.admin_panel_settings_outlined, const Key('adminHomeTab')),
            selectedIcon: _tabIcon(Icons.admin_panel_settings, const Key('adminHomeTab')),
            label: 'Hub',
          ),
        ),
        _Dest(
          location: '/businesses',
          branchIndex: 2,
          destination: NavigationDestination(
            icon: _tabIcon(Icons.storefront_outlined, const Key('exploreTab')),
            selectedIcon: _tabIcon(Icons.storefront, const Key('exploreTab')),
            label: 'Explore',
          ),
        ),
        notifications,
        account,
      ];
    }

    return [
      _Dest(
        location: '/home',
        branchIndex: 0,
        destination: NavigationDestination(
          icon: _tabIcon(Icons.home_outlined, const Key('homeTab')),
          selectedIcon: _tabIcon(Icons.home, const Key('homeTab')),
          label: 'Home',
        ),
      ),
      explore,
      _Dest(
        location: '/favorites',
        branchIndex: 2,
        destination: NavigationDestination(
          icon: _tabIcon(Icons.favorite_border, const Key('favoritesTab')),
          selectedIcon: _tabIcon(Icons.favorite, const Key('favoritesTab')),
          label: 'Favorites',
        ),
      ),
      notifications,
      account,
    ];
  }
}
