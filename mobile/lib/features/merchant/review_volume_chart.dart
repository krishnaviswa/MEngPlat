import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One point of `DashboardStats.reviewVolumeByMonth` -- the backend sends
/// `list[dict[str, Any]]` (`{"month": "2026-01", "count": 3}`), generated on
/// mobile as an opaque `BuiltList<JsonObject>` (no typed Pydantic model on
/// that field). [fromJsonObject] unwraps one entry.
class _VolumePoint {
  const _VolumePoint({required this.month, required this.count});

  final String month;
  final int count;

  static _VolumePoint fromJsonObject(JsonObject object) {
    final map = object.value as Map<String, dynamic>;
    return _VolumePoint(month: map['month'] as String, count: (map['count'] as num).toInt());
  }
}

/// Review-volume-over-months area/line chart -- mobile parity for S-037's
/// web chart upgrade (M-68, S-063 AC 1/6), rendering the same series S-060/
/// M-61 already charted (bar -> line + area fill, not a second chart).
class ReviewVolumeChart extends StatelessWidget {
  const ReviewVolumeChart({required this.volumeByMonth, super.key});

  final BuiltList<JsonObject> volumeByMonth;

  @override
  Widget build(BuildContext context) {
    final points = volumeByMonth.map(_VolumePoint.fromJsonObject).toList();

    return Column(
      key: const Key('reviewVolumeChart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review volume', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (points.every((p) => p.count == 0) || points.isEmpty)
          const Text('No reviews in this range.', key: Key('reviewVolumeChartEmpty'))
        else
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(points[index].month, style: Theme.of(context).textTheme.bodySmall),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble()),
                    ],
                    isCurved: false,
                    barWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                    dotData: const FlDotData(),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
