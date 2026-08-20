import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';

/// Bottom sheet showing a merchant's public review-collection QR code and
/// share link -- mobile parity for S-040's web dashboard QR card (M-71, AC
/// 1). The QR/link always encodes the existing, Accepted **web**
/// `/collect/{slug}` page, not a mobile-only URL -- see S-059's
/// Deep-link/QR scope decision. "Preview in app" is the only in-app-reachable
/// entry point to [CollectReviewScreen].
class ShareReviewLinkSheet extends StatelessWidget {
  const ShareReviewLinkSheet({required this.businessName, required this.slug, super.key});

  final String businessName;
  final String slug;

  static Future<void> show(BuildContext context, {required String businessName, required String slug}) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => ShareReviewLinkSheet(businessName: businessName, slug: slug),
    );
  }

  String get _link => '${AppConfig.webBaseUrl}/collect/$slug';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Text('Share review link', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(businessName, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  QrImageView(
                    key: const Key('shareReviewLinkQr'),
                    data: _link,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(_link, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('shareReviewLinkSheetShareButton'),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: _link)),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share link'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WhatsApp shop updates use a separate QR on your dashboard. This card is the customer review link.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('previewReviewLinkInAppButton'),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/collect/$slug');
            },
            child: const Text('Preview in app'),
          ),
        ],
        ),
      ),
    );
  }
}
