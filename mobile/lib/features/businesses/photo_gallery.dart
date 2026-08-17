import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/media_url.dart';

/// Horizontal gallery with a full-screen lightbox (web PhotoGallery equivalent).
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({required this.photos, super.key});

  final List<PhotoResponse> photos;

  static List<String> urlsFor(BusinessResponse business, List<PhotoResponse> gallery) {
    if (gallery.isNotEmpty) {
      return [for (final photo in gallery) resolveMediaUrl(photo.url)];
    }
    return [
      for (final url in [business.storefrontUrl, business.logoUrl])
        if (url != null && url.isNotEmpty) resolveMediaUrl(url),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('photoGallery'),
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = resolveMediaUrl(photos[index].url);
              return GestureDetector(
                key: Key('galleryThumb_$index'),
                onTap: () => _openLightbox(context, index, [for (final p in photos) resolveMediaUrl(p.url)]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) => SizedBox(
                      width: 96,
                      height: 96,
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openLightbox(BuildContext context, int index, List<String> urls) {
    openLightbox(context, urls: urls, initialIndex: index);
  }

  /// Public entry point so other features (e.g. review photos, S-058) can
  /// reuse the lightbox without duplicating it or making [_Lightbox] public.
  static void openLightbox(BuildContext context, {required List<String> urls, required int initialIndex}) {
    showDialog<void>(
      context: context,
      builder: (context) => _Lightbox(urls: urls, initialIndex: initialIndex),
    );
  }
}

class FallbackPhotoStrip extends StatelessWidget {
  const FallbackPhotoStrip({required this.urls, super.key});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('photoGallery'),
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => GestureDetector(
              key: Key('galleryThumb_$index'),
              onTap: () => PhotoGallery.openLightbox(context, urls: urls, initialIndex: index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[index],
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => SizedBox(
                    width: 96,
                    height: 96,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Lightbox extends StatelessWidget {
  const _Lightbox({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('photoLightbox'),
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (context, index) => InteractiveViewer(
              child: Image.network(
                urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              key: const Key('closeLightbox'),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
