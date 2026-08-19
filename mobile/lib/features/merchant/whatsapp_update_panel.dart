import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'merchant_providers.dart';

Map<String, Object?> jsonObjectMap(JsonObject object) {
  final value = object.value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

/// WhatsApp shop-update QR + read-only suggestion list (M-79 merchant half).
class WhatsAppUpdatePanel extends ConsumerStatefulWidget {
  const WhatsAppUpdatePanel({required this.business, super.key});

  final BusinessResponse business;

  @override
  ConsumerState<WhatsAppUpdatePanel> createState() => _WhatsAppUpdatePanelState();
}

class _WhatsAppUpdatePanelState extends ConsumerState<WhatsAppUpdatePanel> {
  WhatsAppLinkResponse? _link;
  List<WhatsAppDraftResponse> _drafts = [];
  String? _error;
  bool _loading = true;

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
    _load();
  }

  @override
  void didUpdateWidget(covariant WhatsAppUpdatePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final link = await repo.createWhatsAppLink(widget.business.id);
      var drafts = <WhatsAppDraftResponse>[];
      try {
        drafts = await repo.whatsappDrafts(widget.business.id);
      } catch (_) {
        drafts = [];
      }
      if (!mounted) return;
      setState(() {
        _link = link;
        _drafts = drafts;
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

  String _statusLabel(DraftStatus status) {
    if (status == DraftStatus.pending) return 'Pending admin review';
    if (status == DraftStatus.applied) return 'Applied';
    if (status == DraftStatus.discarded) return 'Discarded';
    return status.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('whatsAppUpdatePanel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update shop via WhatsApp', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Suggestions only — an admin approves each update before it goes live.',
          key: const Key('whatsAppSuggestionDisclaimer'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ] else ...[
          if (_link?.available == true && _link?.waUrl != null) ...[
            Center(
              child: QrImageView(
                key: const Key('whatsAppQr'),
                data: _link!.waUrl!,
                size: 140,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(_link!.waUrl!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('shareWhatsAppLinkButton'),
              onPressed: () => SharePlus.instance.share(ShareParams(text: _link!.waUrl!)),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share WhatsApp link'),
            ),
          ] else
            const Text('WhatsApp updates are not configured yet. Ask an admin to set the platform WhatsApp number.'),
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('WhatsApp updates', style: Theme.of(context).textTheme.titleSmall),
            for (final draft in _drafts)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_statusLabel(draft.status)),
                      if (draft.degraded == true)
                        Text('Mock/degraded data.', style: Theme.of(context).textTheme.bodySmall),
                      for (final entry in jsonObjectMap(draft.extractedFields).entries)
                        if (entry.value != null && '${entry.value}'.isNotEmpty)
                          Text(
                            '${_labels[entry.key] ?? entry.key} (suggestion): ${entry.value is Map || entry.value is List ? entry.value : entry.value}',
                          ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}
