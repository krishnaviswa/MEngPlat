import 'package:flutter/material.dart';

/// Simple sentiment bars — no extra chart package (S-031).
class SentimentBreakdown extends StatelessWidget {
  const SentimentBreakdown({required this.counts, super.key});

  final Map<String, int> counts;

  static const _labels = {
    'positive': 'Positive',
    'neutral': 'Neutral',
    'negative': 'Negative',
  };

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final theme = Theme.of(context);
    return Column(
      key: const Key('sentimentBreakdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sentiment breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (total == 0)
          Text('No sentiment data yet.', style: theme.textTheme.bodyMedium)
        else
          for (final key in _labels.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(_labels[key]!, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (counts[key] ?? 0) / total,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${counts[key] ?? 0}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
      ],
    );
  }
}
