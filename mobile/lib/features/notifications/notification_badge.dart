import 'package:flutter/material.dart';

/// Small unread-count badge (capped "9+" display), hidden entirely at count
/// 0 (AC1). Meant to sit on top of a bell icon via a [Stack].
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 9 ? '9+' : '$count';

    return Container(
      key: const Key('notificationBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, height: 1, color: Theme.of(context).colorScheme.onError),
      ),
    );
  }
}
