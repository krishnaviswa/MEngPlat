import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/media_url.dart';
import '../auth/auth_provider.dart';
import '../theme/theme_toggle_button.dart';

/// Identity + logout (S-027 / M-49). Profile edit is S-029 / M-48.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          const ThemeToggleButton(),
          TextButton(
            key: const Key('brandHomeLink'),
            onPressed: () => context.go('/businesses'),
            child: const Text('MerchantHub AI'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your account'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  key: const Key('accountIdentity'),
                  leading: CircleAvatar(
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(resolveMediaUrl(avatarUrl)) : null,
                    child: avatarUrl == null || avatarUrl.isEmpty ? Text(_initials(user.fullName)) : null,
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email ?? user.phone ?? ''),
                ),
                ListTile(
                  key: const Key('profileLink'),
                  title: const Text('Profile'),
                  subtitle: const Text('Name, contact, and role'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/account/profile'),
                ),
                ListTile(
                  key: const Key('supportLink'),
                  title: const Text('Support'),
                  subtitle: const Text('Contact and tickets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('logoutButton'),
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Logout'),
                ),
              ],
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
