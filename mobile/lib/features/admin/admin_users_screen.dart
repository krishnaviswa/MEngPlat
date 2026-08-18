import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'admin_providers.dart';

/// Admin user suspend/reactivate (M-64, S-061 AC 8-9).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<UserResponse> _users = [];
  String? _error;
  bool _loading = true;
  String? _actingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref.read(adminRepositoryProvider).listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _suspend(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(adminRepositoryProvider).suspendUser(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _reactivate(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(adminRepositoryProvider).reactivateUser(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAdminId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      key: const Key('adminUsersScreen'),
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    )
                  : _users.isEmpty
                      ? const Center(child: Text('No users'))
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            // AC 9: hide the controls entirely for admin rows
                            // and the signed-in admin's own row, rather than
                            // surface-then-refuse the backend's 400.
                            final controlsHidden = user.role == UserRole.admin || user.id == currentAdminId;
                            return ListTile(
                              title: Text(user.fullName),
                              subtitle: Text('${user.email ?? user.phone ?? ''} · ${user.role.name}'),
                              trailing: controlsHidden
                                  ? Text(user.isActive ? 'Active' : 'Suspended')
                                  : user.isActive
                                      ? OutlinedButton(
                                          key: Key('suspendUser-${user.id}'),
                                          onPressed: _actingId == user.id ? null : () => _suspend(user.id),
                                          child: const Text('Suspend'),
                                        )
                                      : FilledButton(
                                          key: Key('reactivateUser-${user.id}'),
                                          onPressed: _actingId == user.id ? null : () => _reactivate(user.id),
                                          child: const Text('Reactivate'),
                                        ),
                            );
                          },
                        ),
            ),
    );
  }
}
