import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../businesses/business_list_provider.dart';

class ReportShopButton extends ConsumerWidget {
  const ReportShopButton({required this.businessId, required this.isOwnBusiness, super.key});

  final String businessId;
  final bool isOwnBusiness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOwnBusiness) return const SizedBox.shrink();
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    return OutlinedButton(
      key: const Key('reportShopButton'),
      onPressed: () {
        if (!loggedIn) {
          context.push('/login');
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => _ReportShopSheet(businessId: businessId),
        );
      },
      child: const Text('Report this shop'),
    );
  }
}

class _ReportShopSheet extends ConsumerStatefulWidget {
  const _ReportShopSheet({required this.businessId});

  final String businessId;

  @override
  ConsumerState<_ReportShopSheet> createState() => _ReportShopSheetState();
}

class _ReportShopSheetState extends ConsumerState<_ReportShopSheet> {
  final _reason = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.length < 10) {
      setState(() => _error = 'Please describe the issue (at least 10 characters).');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(businessRepositoryProvider).reportShop(businessId: widget.businessId, reason: reason);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Report this shop', style: Theme.of(context).textTheme.titleMedium),
          TextField(
            key: const Key('reportShopReasonField'),
            controller: _reason,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('submitShopReportButton'),
            onPressed: _submitting ? null : _submit,
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
