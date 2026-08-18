import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../merchant/whatsapp_update_panel.dart';
import 'admin_providers.dart';

/// Admin queue for WhatsApp-derived profile suggestions (M-79).
class AdminWhatsAppQueueScreen extends ConsumerStatefulWidget {
  const AdminWhatsAppQueueScreen({super.key});

  @override
  ConsumerState<AdminWhatsAppQueueScreen> createState() => _AdminWhatsAppQueueScreenState();
}

class _AdminWhatsAppQueueScreenState extends ConsumerState<AdminWhatsAppQueueScreen> {
  List<AdminWhatsAppDraftResponse> _items = [];
  String? _error;
  bool _loading = true;
  String? _actingId;
  final _edits = <String, Map<String, String>>{};

  static const _editable = ['description', 'address', 'phone', 'website'];
  static const _labels = {
    'description': 'Description',
    'address': 'Address',
    'business_hours': 'Hours',
    'phone': 'Phone',
    'website': 'Website',
  };

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
      final queue = await ref.read(adminRepositoryProvider).listWhatsAppDrafts();
      if (!mounted) return;
      setState(() {
        _items = queue.items.toList();
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

  Future<void> _approve(AdminWhatsAppDraftResponse draft) async {
    setState(() => _actingId = draft.id);
    try {
      final fields = <String, String>{};
      final extracted = jsonObjectMap(draft.extractedFields);
      final edits = _edits[draft.id] ?? {};
      for (final key in _editable) {
        if (edits.containsKey(key)) {
          fields[key] = edits[key]!;
        } else if (extracted[key] != null && '${extracted[key]}'.isNotEmpty) {
          fields[key] = '${extracted[key]}';
        }
      }
      await ref.read(adminRepositoryProvider).approveWhatsAppDraft(
        draft.id,
        fields: fields.isEmpty ? null : JsonObject(fields),
      );
      if (!mounted) return;
      setState(() => _items = _items.where((item) => item.id != draft.id).toList());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _reject(String draftId) async {
    setState(() => _actingId = draftId);
    try {
      await ref.read(adminRepositoryProvider).rejectWhatsAppDraft(draftId);
      if (!mounted) return;
      setState(() => _items = _items.where((item) => item.id != draftId).toList());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminWhatsAppQueueScreen'),
      appBar: AppBar(title: const Text('WhatsApp drafts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Suggestions only — approve writes to the live listing; reject leaves it unchanged.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No WhatsApp suggestions waiting for review', key: Key('whatsAppQueueEmpty')),
                    )
                  else
                    for (final draft in _items)
                      Card(
                        key: Key('whatsAppDraft-${draft.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(draft.businessName, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8),
                              for (final key in _editable)
                                if (jsonObjectMap(draft.extractedFields)[key] != null ||
                                    (_edits[draft.id]?[key] != null))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: TextFormField(
                                      key: Key('whatsAppEdit-$key-${draft.id}'),
                                      initialValue: _edits[draft.id]?[key] ??
                                          '${jsonObjectMap(draft.extractedFields)[key] ?? ''}',
                                      decoration: InputDecoration(
                                        labelText: '${_labels[key] ?? key} (suggestion)',
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        _edits[draft.id] = {...?_edits[draft.id], key: value};
                                      },
                                    ),
                                  ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    key: Key('approveWhatsApp-${draft.id}'),
                                    onPressed: _actingId == draft.id ? null : () => _approve(draft),
                                    child: const Text('Approve'),
                                  ),
                                  OutlinedButton(
                                    key: Key('rejectWhatsApp-${draft.id}'),
                                    onPressed: _actingId == draft.id ? null : () => _reject(draft.id),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}
