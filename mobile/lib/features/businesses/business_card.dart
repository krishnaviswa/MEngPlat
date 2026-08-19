import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/media_url.dart';
import '../favorites/favorite_toggle_button.dart';
import '../reviews/rating_stars.dart';

/// Listing card with storefront/logo (or placeholder), name, place, rating.
/// Shared by Explore and Favorites so photo treatment stays consistent (M-24).
class BusinessCard extends StatelessWidget {
  const BusinessCard({
    required this.business,
    this.onTap,
    this.onFavoriteToggled,
    super.key,
  });

  final BusinessResponse business;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteToggled;

  String? get _photoUrl {
    final url = business.storefrontUrl ?? business.logoUrl;
    if (url == null || url.isEmpty) return null;
    return resolveMediaUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _photoUrl;
    final place = [business.city, business.state].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final category = business.categories?.isNotEmpty == true ? business.categories!.first.name : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null)
                    Image.network(
                      photoUrl,
                      key: const Key('businessPhoto'),
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                    )
                  else
                    const _PhotoPlaceholder(),
                  if (category != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(category, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  // S-062/M-66: paid, fixed-period placement fact -- not an AI
                  // quality score. Opposite corner from the category chip,
                  // matching web's BusinessCard.tsx (absolute right-3 top-3).
                  if (business.isFeatured == true)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Chip(
                        key: const Key('featuredBadge'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFEF3C7),
                        side: BorderSide.none,
                        label: const Text('Featured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              title: Text(business.name),
              subtitle: place.isEmpty ? null : Text(place),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RatingStars(rating: business.averageRating, size: 14),
                          const SizedBox(width: 4),
                          Text(business.averageRating.toStringAsFixed(1)),
                        ],
                      ),
                      Text('${business.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  FavoriteToggleButton(businessId: business.id, onToggled: onFavoriteToggled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('businessPhotoPlaceholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE), Color(0xFFFFE4E6)],
        ),
      ),
      child: const Center(child: Icon(Icons.storefront, size: 48, color: Color(0xFF0284C7))),
    );
  }
}
