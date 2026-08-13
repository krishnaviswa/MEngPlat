import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';

/// Read-only profile (S-027 / M-49). No edit forms — that is M-48 / P2.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Sign in to view your profile'))
          : ListView(
              key: const Key('profileScreen'),
              children: [
                ListTile(title: const Text('Name'), subtitle: Text(user.fullName)),
                ListTile(title: const Text('Email'), subtitle: Text(user.email)),
                ListTile(title: const Text('Role'), subtitle: Text(user.role.name)),
              ],
            ),
    );
  }
}
