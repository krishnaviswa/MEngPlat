import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import '../notifications/notification_badge.dart';
import '../notifications/notifications_providers.dart';

class _Dest {
  const _Dest({required this.location, required this.destination});

  final String location;
  final NavigationDestination destination;
}

Widget _tabIcon(IconData data, Key key) => Icon(data, key: key);

/// Primary chrome (S-027 / ADR-005): role-aware [NavigationBar] around [child].
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final unreadCount = user == null ? 0 : ref.watch(unreadCountProvider);
    final location = GoRouterState.of(context).uri.path;
    final destinations = _destinationsFor(user, unreadCount);

    var selectedIndex = destinations.indexWhere(
      (d) => location == d.location || location.startsWith('${d.location}/'),
    );
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        key: const Key('primaryNav'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(destinations[index].location),
        destinations: [for (final dest in destinations) dest.destination],
      ),
    );
  }

  List<_Dest> _destinationsFor(UserResponse? user, int unreadCount) {
    if (user == null) {
      return [
        _Dest(
          location: '/businesses',
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
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined, key: Key('notificationsTab')),
        Positioned(right: -6, top: -4, child: NotificationBadge(count: unreadCount)),
      ],
    );
    final notificationsSelected = Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications, key: Key('notificationsTab')),
        Positioned(right: -6, top: -4, child: NotificationBadge(count: unreadCount)),
      ],
    );
    final notifications = _Dest(
      location: '/notifications',
      destination: NavigationDestination(
        icon: notificationsIcon,
        selectedIcon: notificationsSelected,
        label: 'Notifications',
      ),
    );
    final explore = _Dest(
      location: '/businesses',
      destination: NavigationDestination(
        icon: _tabIcon(Icons.storefront_outlined, const Key('exploreTab')),
        selectedIcon: _tabIcon(Icons.storefront, const Key('exploreTab')),
        label: 'Explore',
      ),
    );
    final account = _Dest(
      location: '/account',
      destination: NavigationDestination(
        icon: _tabIcon(Icons.person_outline, const Key('accountTab')),
        selectedIcon: _tabIcon(Icons.person, const Key('accountTab')),
        label: 'Account',
      ),
    );

    if (user.role == UserRole.merchant) {
      return [
        _Dest(
          location: '/merchant',
          destination: NavigationDestination(
            icon: _tabIcon(Icons.dashboard_outlined, const Key('merchantHomeTab')),
            selectedIcon: _tabIcon(Icons.dashboard, const Key('merchantHomeTab')),
            label: 'Home',
          ),
        ),
        explore,
        notifications,
        account,
      ];
    }

    if (user.role == UserRole.admin) {
      return [
        _Dest(
          location: '/admin',
          destination: NavigationDestination(
            icon: _tabIcon(Icons.admin_panel_settings_outlined, const Key('adminHomeTab')),
            selectedIcon: _tabIcon(Icons.admin_panel_settings, const Key('adminHomeTab')),
            label: 'Home',
          ),
        ),
        explore,
        notifications,
        account,
      ];
    }

    return [
      explore,
      _Dest(
        location: '/favorites',
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
