import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 1-5 star rating-mix bar chart -- mobile parity for S-033's web rating mix
/// (M-61, S-060 AC 2). Deliberately a separate widget from
/// [SentimentBreakdown]: that widget's `positive`/`neutral`/`negative` keys
/// are a different DB-computed dimension from `rating_distribution`'s `"1"`
/// -`"5"` star buckets (S-060 Architect spec).
class RatingDistributionChart extends StatelessWidget {
  const RatingDistributionChart({required this.counts, super.key});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);

    return Column(
      key: const Key('ratingDistributionChart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rating mix', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (total == 0)
          const Text('No ratings in this range.', key: Key('ratingDistributionChartEmpty'))
        else
          SizedBox(
            height: 160,
            child: RepaintBoundary(
              child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final star = value.toInt() + 1;
                        if (star < 1 || star > 5) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 4), child: Text('$star★'));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var star = 1; star <= 5; star++)
                    BarChartGroupData(
                      x: star - 1,
                      barRods: [
                        BarChartRodData(
                          toY: (counts['$star'] ?? 0).toDouble(),
                          color: Colors.amber,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ),
          ),
      ],
    );
  }
}
