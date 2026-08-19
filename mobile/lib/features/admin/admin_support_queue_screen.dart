import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'admin_back_app_bar.dart';
import 'admin_providers.dart';

const _ticketStatuses = ['open', 'in_progress', 'resolved'];

class AdminSupportQueueScreen extends ConsumerStatefulWidget {
  const AdminSupportQueueScreen({super.key});

  @override
  ConsumerState<AdminSupportQueueScreen> createState() => _AdminSupportQueueScreenState();
}

class _AdminSupportQueueScreenState extends ConsumerState<AdminSupportQueueScreen> {
  List<SupportTicketResponse> _items = [];
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
      final items = await ref.read(adminRepositoryProvider).listSupportTickets();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(SupportTicketResponse ticket, String status) async {
    setState(() => _actingId = ticket.id);
    try {
      await ref.read(adminRepositoryProvider).updateSupportTicket(ticketId: ticket.id, status: status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminSupportQueueScreen'),
      appBar: adminBackAppBar(context, title: 'Support tickets'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_items.isEmpty) const Text('No support tickets'),
                  for (final ticket in _items)
                    Card(
                      child: ListTile(
                        title: Text('${ticket.name} · ${ticket.status}'),
                        subtitle: Text(ticket.issue),
                        trailing: DropdownButton<String>(
                          key: Key('ticketStatus-${ticket.id}'),
                          value: _ticketStatuses.contains(ticket.status) ? ticket.status : 'open',
                          items: [
                            for (final s in _ticketStatuses) DropdownMenuItem(value: s, child: Text(s)),
                          ],
                          onChanged: _actingId == ticket.id
                              ? null
                              : (value) {
                                  if (value != null) _setStatus(ticket, value);
                                },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
