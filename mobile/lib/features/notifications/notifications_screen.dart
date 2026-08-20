import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import 'notifications_providers.dart';
import 'relative_time.dart';

/// Dedicated pushed Notifications screen (deliberate mobile adaptation of the
/// web's `NotificationBell.tsx` navbar dropdown -- tap icon, push full
/// screen, per the Architect spec). Notification `type`/`title`/`message`
/// are factual event notices, not AI-generated, so no "suggestion"
/// disclaimer applies here (AC10).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start/keep the 30s unread poll even if this screen was opened without
    // the list screen (which normally watches the badge) having mounted first.
    ref.watch(unreadCountProvider);

    final notificationsAsync = ref.watch(notificationsListProvider);
    final unreadCount = notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            key: const Key('markAllReadButton'),
            onPressed: unreadCount == 0
                ? null
                : () => _markAllRead(context, ref),
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsListProvider.future),
        // Keep prior list visible under the RefreshIndicator spinner instead of
        // swapping the whole body for a full-screen CircularProgressIndicator.
        child: notificationsAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const _CenteredScroll(child: MhSkeleton()),
          error: (error, _) => _CenteredScroll(
            child: MhError(error: error, onRetry: () => ref.invalidate(notificationsListProvider)),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const _CenteredScroll(child: Text('No notifications yet'));
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _NotificationTile(notification: notifications[index]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsListProvider.notifier).markAllRead();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final NotificationResponse notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.isRead;

    return ListTile(
      key: Key('notification-${notification.id}'),
      onTap: () => _onTap(context, ref),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: unread
            ? const CircleAvatar(radius: 4, backgroundColor: Colors.blue)
            : const SizedBox(width: 8, height: 8),
      ),
      tileColor: unread ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06) : null,
      title: Text(
        notification.title,
        style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(notification.message),
          const SizedBox(height: 4),
          Text(formatRelativeTime(notification.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsListProvider.notifier).markRead(notification.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (!context.mounted) return;
    _openReviewDestination(context, ref);
  }

  void _openReviewDestination(BuildContext context, WidgetRef ref) {
    if (!_looksLikeReview(notification)) return;
    if (GoRouter.maybeOf(context) == null) return;

    final role = ref.read(authControllerProvider).valueOrNull?.role;
    if (role == UserRole.merchant) {
      context.go('/merchant/reviews');
      return;
    }

    final slug = _stringFromExtra(notification, const ['slug', 'business_slug', 'businessSlug']);
    if (slug != null && slug.isNotEmpty) {
      context.go('/businesses/$slug');
      return;
    }
    context.go('/businesses');
  }
}

bool _looksLikeReview(NotificationResponse notification) {
  final haystack = '${notification.type} ${notification.title} ${notification.message} ${notification.scenario ?? ''}'
      .toLowerCase();
  return haystack.contains('review');
}

String? _stringFromExtra(NotificationResponse notification, List<String> keys) {
  final extra = notification.extraData?.value;
  if (extra is! Map) return null;
  for (final key in keys) {
    final value = extra[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  return null;
}

class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
