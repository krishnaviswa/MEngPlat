import 'dart:async';

import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'admin_back_app_bar.dart';
import 'admin_providers.dart';

/// Admin user suspend/reactivate (M-64) plus search and role chips (M-82, M-85).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<UserResponse> _users = [];
  String? _error;
  bool _loading = true;
  String? _actingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(q: value.trim()));
  }

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref.read(adminRepositoryProvider).listUsers(q: q ?? _search.text.trim());
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyMessage(error);
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
      setState(() => _error = friendlyMessage(error));
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
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAdminId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      key: const Key('adminUsersScreen'),
      appBar: adminBackAppBar(context, title: 'Users'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suspend blocks sign-in; reviews and account records are kept. There is no delete.',
                  key: const Key('adminUsersRetainCopy'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('adminUsersSearchField'),
                  controller: _search,
                  decoration: const InputDecoration(labelText: 'Search name or email', isDense: true),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
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
                            ? ListView(
                                children: const [
                                  SizedBox(height: 48),
                                  Center(child: Text('No users')),
                                ],
                              )
                            : ListView.separated(
                                itemCount: _users.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  final controlsHidden = user.role == UserRole.admin || user.id == currentAdminId;
                                  return ListTile(
                                    title: Text(user.fullName),
                                    subtitle: Text(user.email ?? user.phone ?? ''),
                                    leading: Chip(
                                      key: Key('roleChip-${user.id}'),
                                      label: Text(user.role.name),
                                      visualDensity: VisualDensity.compact,
                                    ),
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
          ),
        ],
      ),
    );
  }
}
