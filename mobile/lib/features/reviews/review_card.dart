import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/config/app_config.dart';
import 'rating_stars.dart';

/// Single review list item: reviewer name, star rating, title/body, an AI
/// sentiment badge (clearly labeled as AI, never a verified fact -- S-023
/// AC2), and a photo strip. Mirrors `frontend/src/components/ReviewCard.tsx`.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final ReviewResponse review;

  static String _resolveUrl(String url) => url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';

  @override
  Widget build(BuildContext context) {
    final sentiment = review.aiAnalysis?.sentiment;
    final photoUrls = review.photoUrls?.toList() ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author?.fullName ?? 'Customer', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    RatingStars(rating: review.rating),
                  ],
                ),
              ),
              if (sentiment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sentimentColor(sentiment).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'AI: ${sentiment.name}',
                    style: TextStyle(fontSize: 12, color: _sentimentColor(sentiment)),
                  ),
                ),
            ],
          ),
          if (review.title != null) ...[
            const SizedBox(height: 8),
            Text(review.title!, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 4),
          Text(review.body),
          if (review.aiAnalysis?.summary != null) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'AI summary (suggestion): ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: review.aiAnalysis!.summary!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _resolveUrl(photoUrls[index]),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _sentimentColor(Sentiment sentiment) {
    if (sentiment == Sentiment.positive) return Colors.green;
    if (sentiment == Sentiment.negative) return Colors.red;
    return Colors.grey;
  }
}
