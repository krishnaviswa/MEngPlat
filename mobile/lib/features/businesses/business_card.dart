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
    return ColoredBox(
      key: const Key('businessPhotoPlaceholder'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.storefront, size: 48)),
    );
  }
}
