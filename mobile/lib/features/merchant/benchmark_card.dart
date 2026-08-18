import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// Compact directory-median card (M-69). Numbers are listings, not an AI score.
class BenchmarkCard extends StatelessWidget {
  const BenchmarkCard({required this.benchmark, super.key});

  final BenchmarkResponse benchmark;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('benchmarkCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How you compare', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Your rating  ${benchmark.ownRating.toDouble().toStringAsFixed(1)}'),
          Text(_medianLine('Category', benchmark.categoryMedian, benchmark.categorySampleSize)),
          Text(_medianLine('City', benchmark.cityMedian, benchmark.citySampleSize)),
          const SizedBox(height: 8),
          Text(
            benchmark.disclaimer,
            key: const Key('benchmarkDisclaimer'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _medianLine(String label, num? median, int sampleSize) {
    if (median == null) return '$label median  Not enough nearby listings yet';
    return '$label median  ${median.toDouble().toStringAsFixed(1)}  ($sampleSize other listings)';
  }
}
