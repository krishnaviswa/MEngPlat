import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'admin_back_app_bar.dart';
import 'admin_providers.dart';

const _reportStatuses = ['open', 'in_progress', 'resolved'];

class AdminBusinessReportsScreen extends ConsumerStatefulWidget {
  const AdminBusinessReportsScreen({super.key});

  @override
  ConsumerState<AdminBusinessReportsScreen> createState() => _AdminBusinessReportsScreenState();
}

class _AdminBusinessReportsScreenState extends ConsumerState<AdminBusinessReportsScreen> {
  List<BusinessReportResponse> _items = [];
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
      final items = await ref.read(adminRepositoryProvider).listBusinessReports();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(BusinessReportResponse report, String status) async {
    setState(() => _actingId = report.id);
    try {
      await ref.read(adminRepositoryProvider).updateBusinessReport(reportId: report.id, status: status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminBusinessReportsScreen'),
      appBar: adminBackAppBar(context, title: 'Shop reports'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_items.isEmpty) const Text('No shop reports'),
                  for (final report in _items)
                    Card(
                      child: ListTile(
                        title: Text('${report.businessName ?? report.businessId} · ${report.status}'),
                        subtitle: Text(
                          '${report.reason}${report.isRepeat == true ? ' · Repeat shop' : ''}',
                          key: report.isRepeat == true ? Key('repeatReport-${report.id}') : null,
                        ),
                        trailing: DropdownButton<String>(
                          key: Key('reportStatus-${report.id}'),
                          value: _reportStatuses.contains(report.status) ? report.status : 'open',
                          items: [
                            for (final s in _reportStatuses) DropdownMenuItem(value: s, child: Text(s)),
                          ],
                          onChanged: _actingId == report.id
                              ? null
                              : (value) {
                                  if (value != null) _setStatus(report, value);
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
