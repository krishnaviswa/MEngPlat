import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';

/// Placeholder role home (S-027). Full merchant/admin dashboards are P4 (`future`).
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({
    super.key,
    required this.title,
    required this.body,
  });

  const RoleHomeScreen.merchant({super.key})
      : title = 'Merchant',
        body =
            'Full merchant dashboard (stats, replies, and business editor) is on the web for now. '
            'You can still browse businesses in this app.';

  const RoleHomeScreen.admin({super.key})
      : title = 'Admin',
        body =
            'Full admin tools (approvals and moderation queues) are on the web for now. '
            'You can still browse businesses in this app.';

  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user.email ?? user.phone ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            Text(body, key: const Key('roleHomeBody')),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('roleHomeExploreButton'),
              onPressed: () => context.go('/businesses'),
              child: const Text('Explore businesses'),
            ),
          ],
        ),
      ),
    );
  }
}
