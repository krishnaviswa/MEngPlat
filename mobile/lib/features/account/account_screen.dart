import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/media_url.dart';
import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import '../theme/theme_toggle_button.dart';

/// Identity + logout (S-027 / M-49). Profile edit is S-029 / M-48.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final avatarUrl = user?.avatarUrl;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          const ThemeToggleButton(),
          TextButton(
            key: const Key('brandHomeLink'),
            onPressed: () => context.go('/home'),
            child: const Text('MerchantHub AI'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your account'))
          : MhCanvas(
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MhCard(
                  accent: MhAccent.sky,
                  child: Row(
                    key: const Key('accountIdentity'),
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(resolveMediaUrl(avatarUrl))
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(_initials(user.fullName), style: theme.textTheme.titleMedium)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(user.email ?? user.phone ?? '', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MhJobTile(
                  key: const Key('profileLink'),
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Name, contact, and photo',
                  accent: MhAccent.violet,
                  onTap: () => context.push('/account/profile'),
                ),
                const SizedBox(height: 8),
                MhJobTile(
                  key: const Key('supportLink'),
                  icon: Icons.support_agent_outlined,
                  title: 'Support',
                  subtitle: 'Contact and tickets',
                  accent: MhAccent.coral,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('logoutButton'),
                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
