import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import 'merchant_providers.dart';

/// Featured boost catalog + in-app checkout start (M-66).
class FeaturedBoostPanel extends ConsumerStatefulWidget {
  const FeaturedBoostPanel({required this.business, super.key});

  final BusinessResponse business;

  @override
  ConsumerState<FeaturedBoostPanel> createState() => _FeaturedBoostPanelState();
}

class _FeaturedBoostPanelState extends ConsumerState<FeaturedBoostPanel> {
  List<FeaturedSku>? _skus;
  PlacementResponse? _placement;
  String? _error;
  bool _loading = true;
  String? _busySku;
  String? _pendingOrderId;
  String? _pendingProvider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FeaturedBoostPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final skus = await repo.featuredSkus();
      final placement = await repo.placement(widget.business.id);
      if (!mounted) return;
      setState(() {
        _skus = skus;
        _placement = placement;
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

  Future<void> _checkout(String skuCode) async {
    setState(() {
      _busySku = skuCode;
      _error = null;
    });
    try {
      final result = await ref.read(paymentsRepositoryProvider).checkoutFeatured(
        businessId: widget.business.id,
        skuCode: skuCode,
      );
      if (!mounted) return;
      setState(() {
        _pendingOrderId = result.providerOrderId;
        _pendingProvider = result.provider;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _busySku = null);
    }
  }

  Future<void> _openWebDashboard() async {
    final uri = Uri.parse('${AppConfig.webBaseUrl}/merchant/dashboard');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the web dashboard. Try again from a browser.")),
      );
    }
  }

  String get _statusText {
    final placement = _placement;
    if (placement == null) return 'Not currently featured';
    if (placement.active) {
      return 'Active until ${placement.placement?.endsAt.toLocal()}';
    }
    if (placement.awaitingApproval == true) {
      return 'Payment received — awaiting admin approval';
    }
    return 'Not currently featured';
  }

  bool get _canBuy {
    final placement = _placement;
    if (placement == null) return true;
    return !placement.active && placement.awaitingApproval != true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('featuredBoostPanel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Featured boost', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Paid search placement for a fixed period. This is not an AI quality score.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ] else ...[
          Text(_statusText, key: const Key('featuredPlacementStatus')),
          const SizedBox(height: 12),
          if (_canBuy)
            for (final sku in _skus ?? const <FeaturedSku>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  key: Key('featuredCheckout-${sku.code}'),
                  onPressed: _busySku == null ? () => _checkout(sku.code) : null,
                  child: Text(
                    _busySku == sku.code
                        ? 'Starting...'
                        : '₹${sku.listedPriceInr} / ${sku.durationDays} days',
                  ),
                ),
              )
          else
            for (final sku in _skus ?? const <FeaturedSku>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('₹${sku.listedPriceInr} / ${sku.durationDays} days'),
              ),
          if (_pendingOrderId != null) ...[
            const SizedBox(height: 8),
            Text(
              _pendingProvider == 'razorpay'
                  ? 'Order $_pendingOrderId created. Finish payment on the web dashboard — cards never go through this app.'
                  : 'Demo order $_pendingOrderId created. An admin records the mock capture, then approves the boost. Cards never go to this app.',
              key: const Key('featuredCheckoutPendingNote'),
            ),
            if (_pendingProvider == 'razorpay') ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('openWebCheckoutButton'),
                onPressed: _openWebDashboard,
                child: const Text('Finish payment on the web dashboard'),
              ),
            ],
          ],
        ],
      ],
    );
  }
}
