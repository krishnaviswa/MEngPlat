import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/collect_deep_link.dart';
import '../../core/config/app_config.dart';

/// Merchant review-collection QR + share sheet.
///
/// One URL: the same website `/collect/{slug}` as the web dashboard QR.
/// Phone cameras only open https. A custom `merchanthub://` QR does not scan.
/// Use [Open review form] to preview collect inside this app.
class ShareReviewLinkSheet extends StatefulWidget {
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

  @override
  State<ShareReviewLinkSheet> createState() => _ShareReviewLinkSheetState();
}

class _ShareReviewLinkSheetState extends State<ShareReviewLinkSheet> {
  final _qrBoundaryKey = GlobalKey();
  bool _preparingImage = false;

  String get _link => collectWebLink(AppConfig.webBaseUrl, widget.slug);

  /// Captures the QR code as a PNG and hands it to the phone's native share
  /// sheet -- lets AirPrint (iOS) / a print service (Android) handle actually
  /// printing it, mirroring web's `CollectQrCard` "Print for shop" button
  /// with no in-app print/PDF pipeline (S-120).
  ///
  /// Writes to a real temp file via `path_provider` rather than sharing raw
  /// bytes -- `share_plus`'s Android/iOS method channel needs an actual file
  /// path to hand off to the OS share sheet; bytes-only `XFile.fromData` only
  /// works on web.
  Future<void> _shareQrImage() async {
    if (_preparingImage) return;
    setState(() => _preparingImage = true);
    try {
      final boundary = _qrBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/review-qr.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: 'review-qr.png')],
          text: 'Scan to leave a review — ${widget.businessName}',
        ),
      );
    } finally {
      if (mounted) setState(() => _preparingImage = false);
    }
  }

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
          Text(widget.businessName, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('previewReviewLinkInAppButton'),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/collect/${widget.slug}');
            },
            child: const Text('Open review form in this app'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _qrBoundaryKey,
                    child: QrImageView(
                      key: const Key('shareReviewLinkQr'),
                      data: _link,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('shareReviewLinkQrImageButton'),
                    onPressed: _preparingImage ? null : _shareQrImage,
                    icon: const Icon(Icons.print),
                    label: Text(_preparingImage ? 'Preparing…' : 'Share QR to print'),
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
