import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/collect_deep_link.dart';
import '../../core/config/app_config.dart';

/// Merchant review-collection QR + share sheet.
///
/// The **QR** encodes [collectAppLink] so a camera opens this app's collect
/// screen (HTTPS App Links are not verified until `assetlinks.json` has a real
/// SHA-256). **Share** still sends the website `/collect/{slug}` URL for
/// customers who do not have the app. WhatsApp shop-update is a separate QR.
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

  String get _webLink => collectWebLink(AppConfig.webBaseUrl, slug);
  String get _appLink => collectAppLink(slug);

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
                    data: _appLink,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to open the review form in MerchantHub',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_appLink, key: const Key('shareReviewAppLinkText'), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  SelectableText(_webLink, key: const Key('shareReviewWebLinkText'), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('shareReviewLinkSheetShareButton'),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: _webLink)),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share website link'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WhatsApp shop updates use a separate QR. That one opens WhatsApp, not this review form.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('previewReviewLinkInAppButton'),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/collect/$slug');
            },
            child: const Text('Open review form in this app'),
          ),
        ],
        ),
      ),
    );
  }
}
