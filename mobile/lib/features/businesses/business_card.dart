import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../favorites/favorite_toggle_button.dart';

/// Shared business row presentation (name, city/state, rating, review
/// count), extracted from `business_list_screen.dart`'s inline `ListTile` so
/// the business list and Favorites list (S-024) stay visually consistent.
/// Hosts [FavoriteToggleButton] as a trailing action.
class BusinessCard extends StatelessWidget {
  const BusinessCard({
    required this.business,
    this.onTap,
    this.onFavoriteToggled,
    super.key,
  });

  final BusinessResponse business;
  final VoidCallback? onTap;

  /// Forwarded to [FavoriteToggleButton.onToggled] so callers (e.g. the
  /// Favorites screen removing a row on un-favorite, AC8) can react locally.
  final ValueChanged<bool>? onFavoriteToggled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(business.name),
      subtitle: Text([business.city, business.state].whereType<String>().join(', ')),
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
                  const Icon(Icons.star, size: 16, color: Colors.amber),
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
    );
  }
}
