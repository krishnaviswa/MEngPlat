import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/collect_deep_link.dart';
import '../../core/config/app_config.dart';

/// Merchant review-collection QR + share sheet.
///
/// One URL: the same website `/collect/{slug}` as the web dashboard QR.
/// Phone cameras only open https. A custom `merchanthub://` QR does not scan.
/// Use [Open review form] to preview collect inside this app.
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

  String get _link => collectWebLink(AppConfig.webBaseUrl, slug);

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
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('previewReviewLinkInAppButton'),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/collect/$slug');
            },
            child: const Text('Open review form in this app'),
          ),
          const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  SelectableText(_link, key: const Key('shareReviewWebLinkText'), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Customers scan this to open the website review page. WhatsApp shop updates use a different QR.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('shareReviewLinkSheetShareButton'),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: _link)),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share link'),
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
