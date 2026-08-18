import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/merchant/dashboard_repository.dart';
import 'package:merchanthub_mobile/features/merchant/merchant_dashboard_screen.dart';
import 'package:merchanthub_mobile/features/merchant/merchant_providers.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

UserResponse _merchant() => UserResponse((b) => b
  ..id = 'm-1'
  ..email = 'merchant@example.com'
  ..fullName = 'Mina Merchant'
  ..role = UserRole.merchant
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _owned({
  String id = 'biz-1',
  String name = "Mina's Cafe",
  BusinessStatus status = BusinessStatus.approved,
}) =>
    BusinessResponse((b) => b
      ..id = id
      ..name = name
      ..slug = 'minas-cafe'
      ..address = '1 Main St'
      ..city = 'Springfield'
      ..country = 'US'
      ..status = status
      ..averageRating = 4.5
      ..reviewCount = 2);

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _merchant();
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository(this.mine) : super(ApiClient());

  final List<BusinessResponse> mine;

  @override
  Future<List<BusinessResponse>> listMine() async => mine;
}

class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository() : super(ApiClient());

  @override
  Future<DashboardStats> merchantStats(String businessId, {String range = 'all'}) async {
    return DashboardStats((b) => b
      ..totalReviews = 2
      ..averageRating = 4.5
      ..sentimentBreakdown.addAll({'positive': 2, 'neutral': 0, 'negative': 0}));
  }

  @override
  Future<MerchantInsightsResponse> insights(String businessId) async {
    return MerchantInsightsResponse((b) => b
      ..businessId = businessId
      ..merchantSummary = 'Guests mention friendly staff.');
  }
}

/// S-060/M-61: records every `range` a fake dashboard repository is called
/// with, and can return different [DashboardStats] per range (via
/// [statsByRange]) so tests can prove the screen actually refetches and
/// re-renders on range change (AC 3), rather than client-side filtering an
/// already-fetched payload.
class _RecordingDashboardRepository extends DashboardRepository {
  _RecordingDashboardRepository({
    DashboardStats? stats,
    this.statsByRange,
    this.csvResult,
    this.csvError,
    this.csvCompleter,
  }) : _stats = stats ?? _defaultStats(),
       super(ApiClient());

  final DashboardStats _stats;
  final Map<String, DashboardStats>? statsByRange;
  final String? csvResult;
  final Object? csvError;
  final Completer<String>? csvCompleter;

  final List<String> statsRangesRequested = [];
  final List<String> csvRangesRequested = [];

  static DashboardStats _defaultStats() => DashboardStats((b) => b
    ..totalReviews = 2
    ..averageRating = 4.5
    ..sentimentBreakdown.addAll({'positive': 2, 'neutral': 0, 'negative': 0}));

  @override
  Future<DashboardStats> merchantStats(String businessId, {String range = 'all'}) async {
    statsRangesRequested.add(range);
    return statsByRange?[range] ?? _stats;
  }

  @override
  Future<MerchantInsightsResponse> insights(String businessId) async {
    return MerchantInsightsResponse((b) => b
      ..businessId = businessId
      ..merchantSummary = 'Guests mention friendly staff.');
  }

  @override
  Future<String> reviewsCsv(String businessId, {String range = 'all'}) async {
    csvRangesRequested.add(range);
    if (csvCompleter != null) return csvCompleter!.future;
    if (csvError != null) throw csvError!;
    return csvResult ?? 'month,count\n2026-01,3\n';
  }
}

/// S-060/M-61 AC 6: fakes `share_plus`'s platform-interface layer (its own
/// documented testing seam, see `SharePlatform.instance` setter) so the CSV
/// export flow's actual `SharePlus.instance.share(...)` call can be asserted
/// without a real device share sheet.
class _FakeSharePlatform extends SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  List<BusinessResponse> mine = const [],
  DashboardRepository? dashboardRepository,
}) async {
  // S-060 added a range selector + two fl_chart sections + a reply-rate/CSV
  // row to this screen's ListView -- the default 800x600 test surface is
  // too short to build (and thus find.byKey) content further down the list
  // (e.g. aiInsightsDisclaimer), same class of fix S-058/S-059's Tester
  // documented for other screens.
  await tester.binding.setSurfaceSize(const Size(400, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository(mine)),
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository ?? _FakeDashboardRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MerchantDashboardScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('S-031 AC3: zero businesses shows empty state and create CTA', (tester) async {
    await _pumpDashboard(tester);
    expect(find.byKey(const Key('merchantEmptyState')), findsOneWidget);
    expect(find.byKey(const Key('createBusinessCta')), findsOneWidget);
    expect(find.textContaining('on the web for now'), findsNothing);
  });

  testWidgets('S-031 AC1/AC4/AC9: dashboard tiles and suggestion-only insights', (tester) async {
    await _pumpDashboard(tester, mine: [_owned()]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('merchantHomeScreen')), findsOneWidget);
    expect(find.byKey(const Key('totalReviewsTile')), findsOneWidget);
    expect(find.byKey(const Key('averageRatingTile')), findsOneWidget);
    expect(find.byKey(const Key('statusTile')), findsOneWidget);
    expect(find.byKey(const Key('aiInsightsDisclaimer')), findsOneWidget);
    expect(find.textContaining('Suggestions only'), findsOneWidget);
    expect(find.textContaining('Guests mention friendly staff.'), findsOneWidget);
  });

  testWidgets('S-031 AC2: multi-business selector is shown', (tester) async {
    await _pumpDashboard(tester, mine: [_owned(), _owned(id: 'biz-2', name: 'Second Shop')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('merchantBusinessSelector')), findsOneWidget);
  });

  testWidgets('S-059 AC1/AC6: "Share review link" is shown for an approved business owned by this merchant', (
    tester,
  ) async {
    // Widen the surface -- the ShareReviewLinkSheet's QR + link + two
    // buttons overflow the default 800x600 test surface height, and the
    // dashboard's own action row needs its usual width to avoid its own
    // (pre-existing, unrelated) overflow.
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDashboard(tester, mine: [_owned(status: BusinessStatus.approved)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shareReviewLinkButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shareReviewLinkButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shareReviewLinkQr')), findsOneWidget);
  });

  testWidgets('S-059 AC1: "Share review link" is not shown for a pending (not-yet-approved) business', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned(status: BusinessStatus.pending)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shareReviewLinkButton')), findsNothing);
  });

  testWidgets(
    'S-060 AC3/AC5: choosing a date range triggers a live refetch with that range, and reply-rate reflects it',
    (tester) async {
      final repo = _RecordingDashboardRepository(
        statsByRange: {
          'all': DashboardStats((b) => b
            ..totalReviews = 2
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 2, 'neutral': 0, 'negative': 0})
            ..replyRate = 0.5),
          '30': DashboardStats((b) => b
            ..totalReviews = 0
            ..averageRating = 0
            ..sentimentBreakdown.addAll({'positive': 0, 'neutral': 0, 'negative': 0})),
        },
      );

      await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

      // Initial load is the default range ('all'), matching the backend
      // default -- not a client-side filter.
      expect(repo.statsRangesRequested, ['all']);
      expect(find.textContaining('50%'), findsOneWidget);

      await tester.tap(find.text('Last 30 days'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // A second, live network round trip with the new range -- not a
      // client-side filter of the already-fetched all-time payload.
      expect(repo.statsRangesRequested, ['all', '30']);
      expect(find.text('No reviews in this range'), findsOneWidget);
    },
  );

  testWidgets('S-060 AC1/AC8: review volume chart shows empty-state copy when there is no volume data', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: _RecordingDashboardRepository());

    expect(find.byKey(const Key('reviewVolumeChart')), findsOneWidget);
    expect(find.byKey(const Key('reviewVolumeChartEmpty')), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('S-060 AC1: review volume chart renders bars when review_volume_by_month has data', (tester) async {
    final stats = DashboardStats((b) => b
      ..totalReviews = 3
      ..averageRating = 4.5
      ..sentimentBreakdown.addAll({'positive': 3, 'neutral': 0, 'negative': 0})
      ..reviewVolumeByMonth.addAll([
        JsonObject({'month': '2026-06', 'count': 1}),
        JsonObject({'month': '2026-07', 'count': 2}),
      ]));

    await _pumpDashboard(
      tester,
      mine: [_owned()],
      dashboardRepository: _RecordingDashboardRepository(stats: stats),
    );

    expect(find.byKey(const Key('reviewVolumeChartEmpty')), findsNothing);
    expect(find.byType(BarChart), findsWidgets);
  });

  testWidgets('S-060 AC2/AC8: rating distribution chart shows empty-state copy when there are no ratings', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: _RecordingDashboardRepository());

    expect(find.byKey(const Key('ratingDistributionChart')), findsOneWidget);
    expect(find.byKey(const Key('ratingDistributionChartEmpty')), findsOneWidget);
  });

  testWidgets('S-060 AC2: rating distribution chart renders bars when rating_distribution has data', (
    tester,
  ) async {
    final stats = DashboardStats((b) => b
      ..totalReviews = 2
      ..averageRating = 4.5
      ..sentimentBreakdown.addAll({'positive': 2, 'neutral': 0, 'negative': 0})
      ..ratingDistribution.addAll({'5': 2, '4': 0, '3': 0, '2': 0, '1': 0}));

    await _pumpDashboard(
      tester,
      mine: [_owned()],
      dashboardRepository: _RecordingDashboardRepository(stats: stats),
    );

    expect(find.byKey(const Key('ratingDistributionChartEmpty')), findsNothing);
    expect(find.byType(BarChart), findsWidgets);
  });

  testWidgets('S-060 AC5/AC8: reply rate shows "No reviews in this range" (never 0%) when reply_rate is null', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: _RecordingDashboardRepository());

    final tile = find.byKey(const Key('replyRateTile'));
    expect(tile, findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('No reviews in this range')), findsOneWidget);
    expect(find.descendant(of: tile, matching: find.textContaining('0%')), findsNothing);
  });

  testWidgets('S-060 AC5: reply rate renders as a percentage when reply_rate is present', (tester) async {
    final stats = DashboardStats((b) => b
      ..totalReviews = 4
      ..averageRating = 4.5
      ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})
      ..replyRate = 0.75);

    await _pumpDashboard(
      tester,
      mine: [_owned()],
      dashboardRepository: _RecordingDashboardRepository(stats: stats),
    );

    final tile = find.byKey(const Key('replyRateTile'));
    expect(find.descendant(of: tile, matching: find.text('75%')), findsOneWidget);
  });

  testWidgets(
    'S-060 AC6: export CSV calls the repository with the current business/range and shares the resulting file',
    (tester) async {
      final repo = _RecordingDashboardRepository(csvResult: 'month,count\n2026-01,3\n');
      final fakeShare = _FakeSharePlatform();
      final previousPlatform = SharePlatform.instance;
      SharePlatform.instance = fakeShare;
      addTearDown(() => SharePlatform.instance = previousPlatform);

      await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

      await tester.tap(find.byKey(const Key('exportCsvButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.csvRangesRequested, ['all']);
      expect(fakeShare.lastParams, isNotNull);
      expect(fakeShare.lastParams!.files, hasLength(1));
      expect(fakeShare.lastParams!.files!.single.mimeType, 'text/csv');
      // `XFile.fromData`'s own `name:` argument is a no-op on non-web
      // platforms (cross_file, verified by reading its io implementation) --
      // `fileNameOverrides` is the real, respected mechanism `share_plus`
      // documents for naming an in-memory-bytes file (S-060 Tester finding,
      // fixed in `_exportCsv`).
      expect(fakeShare.lastParams!.fileNameOverrides, ['reviews-biz-1-all.csv']);
    },
  );

  testWidgets('S-060 AC6: export button shows a busy state while the CSV request is in flight', (tester) async {
    final completer = Completer<String>();
    await _pumpDashboard(
      tester,
      mine: [_owned()],
      dashboardRepository: _RecordingDashboardRepository(csvCompleter: completer),
    );

    await tester.tap(find.byKey(const Key('exportCsvButton')));
    await tester.pump();

    expect(find.text('Exporting...'), findsOneWidget);

    // Resolve the in-flight CSV fetch. The real success path then hands off
    // to `share_plus` -- no platform mock is installed for this test, so the
    // resulting (uncaught-by-us) platform-channel failure is expected to be
    // absorbed by the screen's own generic catch, same as any other export
    // failure; this test only asserts the busy-state transition, not the
    // share outcome (covered separately above).
    completer.complete('month,count\n2026-01,3\n');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Exporting...'), findsNothing);
  });

  testWidgets('S-060 AC6: CSV export failure surfaces through the existing _error pattern, not a silent failure', (
    tester,
  ) async {
    final repo = _RecordingDashboardRepository(csvError: Exception('403: not your business'));
    await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

    await tester.tap(find.byKey(const Key('exportCsvButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('403: not your business'), findsOneWidget);
  });
}
