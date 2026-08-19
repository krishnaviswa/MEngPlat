import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_provider.dart';
import 'support_repository.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _issue = TextEditingController();
  final _businessId = TextEditingController();
  SupportContactResponse? _contact;
  List<SupportTicketResponse> _mine = [];
  List<BusinessReportResponse> _reports = [];
  String? _error;
  String? _ok;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _issue.dispose();
    _businessId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(supportRepositoryProvider);
      final contact = await repo.contact();
      final user = ref.read(authControllerProvider).valueOrNull;
      var tickets = <SupportTicketResponse>[];
      var reports = <BusinessReportResponse>[];
      if (user != null) {
        tickets = await repo.myTickets();
        reports = await repo.myReports();
      }
      if (!mounted) return;
      setState(() {
        _contact = contact;
        _mine = tickets;
        _reports = reports;
        _loading = false;
        if (user != null && _name.text.isEmpty) _name.text = user.fullName;
        if (user != null && _phone.text.isEmpty) _phone.text = user.phone ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
      _ok = null;
    });
    try {
      final ticket = await ref.read(supportRepositoryProvider).createTicket(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            issue: _issue.text.trim(),
            businessId: _businessId.text.trim().isEmpty ? null : _businessId.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _ok = 'Ticket submitted (${ticket.status}). Reference ${ticket.id.substring(0, ticket.id.length.clamp(0, 8))}…';
        _issue.clear();
        _mine = [ticket, ..._mine];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('supportScreen'),
      appBar: AppBar(title: const Text('Support')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_contact != null) ...[
                    Text('Email ${_contact!.email}', key: const Key('supportContactEmail')),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse('mailto:${_contact!.email}')),
                      child: const Text('Email support'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_ok != null)
                    Text(_ok!, key: const Key('supportTicketSuccess'), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  TextField(
                    key: const Key('supportNameField'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    key: const Key('supportPhoneField'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  TextField(
                    key: const Key('supportIssueField'),
                    controller: _issue,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Issue'),
                  ),
                  TextField(
                    key: const Key('supportBusinessIdField'),
                    controller: _businessId,
                    decoration: const InputDecoration(labelText: 'Related business ID (optional)'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('submitSupportTicketButton'),
                    onPressed: _submitting ? null : _submit,
                    child: const Text('Submit ticket'),
                  ),
                  if (_mine.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Your tickets', style: Theme.of(context).textTheme.titleMedium),
                    for (final t in _mine)
                      ListTile(
                        title: Text(t.status),
                        subtitle: Text(t.issue),
                      ),
                  ],
                  if (_reports.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Your shop reports', style: Theme.of(context).textTheme.titleMedium),
                    for (final r in _reports)
                      ListTile(
                        title: Text(r.businessName ?? r.businessId),
                        subtitle: Text('${r.status}${r.isRepeat == true ? ' · repeat' : ''}'),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
