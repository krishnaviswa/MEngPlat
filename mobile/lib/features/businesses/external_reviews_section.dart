import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../reviews/rating_stars.dart';

/// Public "Also reviewed on Google" strip (M-80). Hidden when empty.
class ExternalReviewsSection extends StatelessWidget {
  const ExternalReviewsSection({required this.reviews, super.key});

  final List<ExternalReviewResponse> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        key: const Key('externalReviewsSection'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Also reviewed on Google', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Up to 5 Google samples pulled in by the owner — not a full history, and not mixed into MerchantHub ratings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final review in reviews.take(5))
            Card(
              child: ListTile(
                title: Text(review.authorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingStars(rating: review.rating.toDouble()),
                    Text(review.body ?? 'No written review'),
                    if (review.sourceUrl != null)
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(review.sourceUrl!), mode: LaunchMode.externalApplication),
                        child: const Text('View on Google'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
