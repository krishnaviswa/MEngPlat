import 'package:flutter/material.dart';

import '../rating_stars.dart';

/// Tap-only star step. Every rating (1-5) advances identically — no low-star
/// intercept (S-040 parity).
class GamifiedStarStep extends StatelessWidget {
  const GamifiedStarStep({required this.rating, required this.onSelect, super.key});

  final int rating;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('How was your experience?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        RatingStars(rating: rating, size: 48, onChanged: onSelect),
        const SizedBox(height: 8),
        Text('Tap a star to continue', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
