import 'package:flutter/material.dart';

/// Simple sentiment bars — no extra chart package (S-031).
class SentimentBreakdown extends StatelessWidget {
  const SentimentBreakdown({required this.counts, super.key});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final keys = ['positive', 'neutral', 'negative'];
    return Column(
      key: const Key('sentimentBreakdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sentiment breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (total == 0)
          const Text('No sentiment data yet.')
        else
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(key)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (counts[key] ?? 0) / total,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${counts[key] ?? 0}'),
                ],
              ),
            ),
      ],
    );
  }
}
