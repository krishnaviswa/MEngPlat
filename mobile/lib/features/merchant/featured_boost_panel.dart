import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import 'merchant_providers.dart';

/// Read-only "Featured boost" info panel -- mobile parity for M-66's
/// browse/display half (S-062). Shows the existing three-SKU catalog and
/// this business's current placement status. Deliberately does **not**
/// start a checkout: `POST /payments/featured/checkout` is never called
/// here -- mobile checkout is a separate, future slice. The "Buy on web
/// dashboard" button is a real, working external-browser hand-off, not a
/// disguised in-app purchase -- see the slice's Deep-link/copy risk note.
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
      final results = await Future.wait([repo.featuredSkus(), repo.placement(widget.business.id)]);
      if (!mounted) return;
      setState(() {
        _skus = results[0] as List<FeaturedSku>;
        _placement = results[1] as PlacementResponse;
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

  Future<void> _openWebCheckout() async {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('featuredBoostPanel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Featured boost', style: Theme.of(context).textTheme.titleMedium),
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
          for (final sku in _skus ?? const <FeaturedSku>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('₹${sku.listedPriceInr} / ${sku.durationDays} days'),
            ),
          const SizedBox(height: 8),
          // Static explanatory copy near the tiles, not solely on the
          // button -- the slice's central scope-leak-risk mitigation.
          const Text(
            'Purchase is completed on the web merchant dashboard for now.',
            key: Key('featuredBuyOnWebNote'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('openWebCheckoutButton'),
            onPressed: _openWebCheckout,
            child: const Text('Buy a featured boost on the web dashboard'),
          ),
        ],
      ],
    );
  }
}
