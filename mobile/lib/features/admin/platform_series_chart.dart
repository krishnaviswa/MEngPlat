import 'package:built_value/json_object.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// One `{bucket, count}` point of a `PlatformAnalyticsSeries.series` entry
/// (S-061 Architect spec).
class _SeriesPoint {
  const _SeriesPoint({required this.count});

  final int count;

  static _SeriesPoint fromJsonObject(JsonObject object) {
    final map = object.value as Map<String, dynamic>;
    return _SeriesPoint(count: (map['count'] as num).toInt());
  }
}

/// Platform time-series chart row (M-62, S-061 AC 1-4): new users, businesses
/// approved, new reviews, new reports -- four small line charts below the
/// admin home screen's stat tiles.
class PlatformSeriesChart extends StatelessWidget {
  const PlatformSeriesChart({required this.series, super.key});

  final PlatformAnalyticsSeries series;

  static const _labels = {
    'new_users': 'New users',
    'businesses_approved': 'Businesses approved',
    'new_reviews': 'New reviews',
    'new_reports': 'New reports',
  };

  @override
  Widget build(BuildContext context) {
    final allEmpty = series.series.values.every(
      (points) => points.every((p) => (p.value as Map<String, dynamic>)['count'] == 0) || points.isEmpty,
    );

    if (allEmpty) {
      return Container(
        key: const Key('platformSeriesEmpty'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No platform activity yet'),
      );
    }

    return Column(
      key: const Key('platformSeriesChart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Platform trends', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in _labels.entries) ...[
          _SingleSeriesChart(seriesKey: entry.key, label: entry.value, series: series),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SingleSeriesChart extends StatelessWidget {
  const _SingleSeriesChart({required this.seriesKey, required this.label, required this.series});

  final String seriesKey;
  final String label;
  final PlatformAnalyticsSeries series;

  @override
  Widget build(BuildContext context) {
    final raw = series.series[seriesKey];
    final points = (raw?.toList() ?? const <JsonObject>[]).map(_SeriesPoint.fromJsonObject).toList();

    final counts = points.map((p) => p.count).toList();
    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount < 1 ? 1 : maxCount) * 1.15;

    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      if (points.isEmpty)
                        const FlSpot(0, 0)
                      else
                        for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble()),
                    ],
                    isCurved: false,
                    barWidth: 2.5,
                    color: theme.colorScheme.primary,
                    dotData: const FlDotData(show: false),
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
