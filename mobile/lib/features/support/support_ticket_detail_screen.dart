import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'support_repository.dart';
import 'ticket_ref.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends ConsumerState<SupportTicketDetailScreen> {
  SupportTicketResponse? _ticket;
  String? _error;
  bool _loading = true;

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
      final ticket = await ref.read(supportRepositoryProvider).getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
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

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    return Scaffold(
      key: const Key('supportTicketDetail'),
      appBar: AppBar(title: const Text('Ticket')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : ticket == null
                  ? const Center(child: Text('Ticket not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          supportTicketRef(ticket.id),
                          key: const Key('supportTicketRef'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${ticket.status}'),
                        const SizedBox(height: 12),
                        Text('Issue', style: Theme.of(context).textTheme.titleSmall),
                        Text(ticket.issue),
                        if (ticket.adminResponse != null && ticket.adminResponse!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Admin response', style: Theme.of(context).textTheme.titleSmall),
                          Text(ticket.adminResponse!),
                        ],
                      ],
                    ),
    );
  }
}
