import 'package:built_value/json_object.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// One `{bucket, count}` point of a `PlatformAnalyticsSeries.series` entry
/// (S-061 Architect spec).
class _SeriesPoint {
  const _SeriesPoint({required this.bucket, required this.count});

  final String bucket;
  final int count;

  static _SeriesPoint fromJsonObject(JsonObject object) {
    final map = object.value as Map<String, dynamic>;
    return _SeriesPoint(
      bucket: map['bucket'] as String? ?? '',
      count: (map['count'] as num).toInt(),
    );
  }
}

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatSeriesBucket(String bucket) {
  final parsed = DateTime.tryParse(bucket);
  if (parsed == null || bucket.isEmpty) return bucket;
  return '${parsed.day} ${_monthShort[parsed.month - 1]}';
}

/// Platform time-series (M-62, S-061): one touchable chart plus a series chooser.
class PlatformSeriesChart extends StatefulWidget {
  const PlatformSeriesChart({required this.series, super.key});

  final PlatformAnalyticsSeries series;

  static const labels = {
    'new_users': 'New users',
    'businesses_approved': 'Businesses approved',
    'new_reviews': 'New reviews',
    'new_reports': 'New reports',
  };

  @override
  State<PlatformSeriesChart> createState() => _PlatformSeriesChartState();
}

class _PlatformSeriesChartState extends State<PlatformSeriesChart> {
  String _seriesKey = 'new_users';

  @override
  Widget build(BuildContext context) {
    final allEmpty = widget.series.series.values.every(
      (points) => points.every((p) => (p.value as Map<String, dynamic>)['count'] == 0) || points.isEmpty,
    );

    if (allEmpty) {
      return Container(
        key: const Key('platformSeriesEmpty'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Text('No platform activity yet', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Column(
      key: const Key('platformSeriesChart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Platform trends', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          key: const Key('platformSeriesChooser'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in PlatformSeriesChart.labels.entries) ...[
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _seriesKey == entry.key,
                  onSelected: (_) => setState(() => _seriesKey = entry.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SingleSeriesChart(seriesKey: _seriesKey, series: widget.series),
      ],
    );
  }
}

class _SingleSeriesChart extends StatelessWidget {
  const _SingleSeriesChart({required this.seriesKey, required this.series});

  final String seriesKey;
  final PlatformAnalyticsSeries series;

  @override
  Widget build(BuildContext context) {
    final raw = series.series[seriesKey];
    final points = (raw?.toList() ?? const <JsonObject>[]).map(_SeriesPoint.fromJsonObject).toList();

    final counts = points.map((p) => p.count).toList();
    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount < 1 ? 1 : maxCount) * 1.15;
    final yInterval = maxY / 2;

    final theme = Theme.of(context);
    final spots = [
      if (points.isEmpty)
        const FlSpot(0, 0)
      else
        for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble()),
    ];

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox.shrink();
                  return Text(
                    value.round().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  if (index != 0 && index != points.length - 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(formatSeriesBucket(points[index].bucket), style: theme.textTheme.bodySmall),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) {
                return [
                  for (final spot in touched)
                    LineTooltipItem(
                      _tooltipLabel(points, spot.x),
                      theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onInverseSurface),
                    ),
                ];
              },
            ),
            getTouchedSpotIndicator: (bar, indexes) {
              return [
                for (final _ in indexes)
                  TouchedSpotIndicatorData(
                    FlLine(color: theme.colorScheme.primary.withValues(alpha: 0.4), strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
              ];
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              barWidth: 2.5,
              color: theme.colorScheme.primary,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  String _tooltipLabel(List<_SeriesPoint> points, double x) {
    final index = x.round().clamp(0, points.isEmpty ? 0 : points.length - 1);
    if (points.isEmpty) return '0';
    final point = points[index];
    final day = formatSeriesBucket(point.bucket);
    if (day.isEmpty) return '${point.count}';
    return '$day · ${point.count}';
  }
}
