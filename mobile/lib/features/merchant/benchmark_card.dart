import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// Directory-median comparison (M-69). Numbers are listings, not an AI score.
class BenchmarkCard extends StatelessWidget {
  const BenchmarkCard({required this.benchmark, super.key});

  final BenchmarkResponse benchmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('benchmarkCard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How you compare', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Your rating  ${benchmark.ownRating.toDouble().toStringAsFixed(1)}',
          style: theme.textTheme.bodyMedium,
        ),
        Text(_medianLine('Category', benchmark.categoryMedian, benchmark.categorySampleSize), style: theme.textTheme.bodyMedium),
        Text(_medianLine('City', benchmark.cityMedian, benchmark.citySampleSize), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          benchmark.disclaimer,
          key: const Key('benchmarkDisclaimer'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _medianLine(String label, num? median, int sampleSize) {
    if (median == null) return '$label median  Not enough nearby listings yet';
    return '$label median  ${median.toDouble().toStringAsFixed(1)}  ($sampleSize other listings)';
  }
}
