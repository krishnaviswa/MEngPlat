import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/admin/platform_series_chart.dart';

/// S-061 (M-62) AC1/AC3/AC4: the platform time-series chart row rendered
/// directly (not through AdminHomeScreen's full load), matching S-034's own
/// coverage split between "chart component" and "screen wiring" tests.

PlatformAnalyticsSeries _series(Map<String, List<int>> counts) {
  return PlatformAnalyticsSeries((b) => b
    ..granularity = PlatformAnalyticsSeriesGranularityEnum.day
    ..days = counts.values.isEmpty ? 0 : counts.values.first.length
    ..series.replace({
      for (final entry in counts.entries)
        entry.key: BuiltList<JsonObject>([
          for (final count in entry.value) JsonObject({'bucket': '2026-01-01', 'count': count}),
        ]),
    }));
}

void main() {
  testWidgets('AC1: renders one chart per series with operational-facts labels', (tester) async {
    final series = _series({
      'new_users': [1, 2, 3],
      'businesses_approved': [0, 1, 0],
      'new_reviews': [4, 5, 6],
      'new_reports': [0, 0, 1],
    });

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlatformSeriesChart(series: series))));

    expect(find.byKey(const Key('platformSeriesChart')), findsOneWidget);
    expect(find.text('New users'), findsOneWidget);
    expect(find.text('Businesses approved'), findsOneWidget);
    expect(find.text('New reviews'), findsOneWidget);
    expect(find.text('New reports'), findsOneWidget);

    expect(tester.getSize(find.byKey(const Key('platformSeriesChart'))).width, greaterThan(300));
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('AC4: chart labels never present the data as AI output', (tester) async {
    final series = _series({
      'new_users': [1],
      'businesses_approved': [1],
      'new_reviews': [1],
      'new_reports': [1],
    });

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlatformSeriesChart(series: series))));

    expect(find.textContaining('AI', findRichText: true), findsNothing);
    expect(find.textContaining('suggestion'), findsNothing);
    expect(find.textContaining('insight'), findsNothing);
  });

  testWidgets('AC3: an all-zero series renders the dashed empty-chart treatment, not a blank chart', (tester) async {
    final series = _series({
      'new_users': [0, 0],
      'businesses_approved': [0, 0],
      'new_reviews': [0, 0],
      'new_reports': [0, 0],
    });

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlatformSeriesChart(series: series))));

    expect(find.byKey(const Key('platformSeriesEmpty')), findsOneWidget);
    expect(find.text('No platform activity yet'), findsOneWidget);
    expect(find.byKey(const Key('platformSeriesChart')), findsNothing);
  });

  testWidgets('AC3: an entirely empty series map (no buckets at all) also uses the empty treatment', (tester) async {
    final series = _series({
      'new_users': [],
      'businesses_approved': [],
      'new_reviews': [],
      'new_reports': [],
    });

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlatformSeriesChart(series: series))));

    expect(find.byKey(const Key('platformSeriesEmpty')), findsOneWidget);
  });
}
