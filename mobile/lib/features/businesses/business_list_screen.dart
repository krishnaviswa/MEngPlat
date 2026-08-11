import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import '../notifications/notification_badge.dart';
import '../notifications/notifications_providers.dart';
import 'business_card.dart';
import 'business_list_provider.dart';

class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessListProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isLoggedIn = user != null;
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Businesses'),
        // ADR-003: this screen is now reachable while logged out (guest
        // browsing) -- a session sees the logout icon (plus any auth-gated
        // entry points below), a guest sees a "Sign in" action instead of a
        // dead/auth-gated icon.
        actions: [
          // S-025 AC8: no entry point reachable anywhere when logged out.
          if (isLoggedIn)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  key: const Key('notificationsButton'),
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
                Positioned(right: 6, top: 6, child: NotificationBadge(count: unreadCount)),
              ],
            ),
          // S-024 AC10: hidden outright (not shown-disabled) for anyone but
          // a logged-in customer -- merchants/admins never favorite, and
          // guests would just bounce off the router's default auth guard.
          if (user?.role == UserRole.customer)
            IconButton(
              key: const Key('favoritesButton'),
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Favorites',
              onPressed: () => context.push('/favorites'),
            ),
          if (isLoggedIn)
            IconButton(
              key: const Key('logoutButton'),
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            )
          else
            IconButton(
              key: const Key('signInButton'),
              icon: const Icon(Icons.login),
              tooltip: 'Sign in',
              onPressed: () => context.push('/login'),
            ),
        ],
      ),
      body: businesses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(businessListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No businesses found'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final business = list[index];
              return BusinessCard(
                business: business,
                onTap: () => context.push('/businesses/${business.slug}'),
              );
            },
          );
        },
      ),
    );
  }
}
