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
import 'package:merchanthub_mobile/features/merchant/payments_repository.dart';
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

mixin _ParityDashboardStubs on DashboardRepository {
  @override
  Future<BenchmarkResponse> benchmark(String businessId) async {
    return BenchmarkResponse(
      (b) => b
        ..businessId = businessId
        ..ownRating = 4.5
        ..categoryMedian = 4.2
        ..cityMedian = 4.0
        ..categorySampleSize = 8
        ..citySampleSize = 12
        ..disclaimer = 'Directory medians from MerchantHub listings — not an AI judgment.',
    );
  }

  @override
  Future<TopicClusterResponse> topicClusters(String businessId) async {
    return TopicClusterResponse(
      (b) => b
        ..businessId = businessId
        ..insufficientData = false
        ..unavailable = false
        ..topics.add(
          TopicItem(
            (t) => t
              ..label = 'Wait time'
              ..count = 4
              ..sentiment = TopicItemSentimentEnum.mixed
              ..exampleQuote = 'Sometimes busy on weekends',
          ),
        ),
    );
  }

  @override
  Future<GoogleReviewsStatusResponse> googleReviewsStatus(String businessId) async {
    return GoogleReviewsStatusResponse(
      (b) => b
        ..linked = false
        ..reviewCount = 0,
    );
  }

  @override
  Future<GooglePlacesSearchResponse> searchGooglePlaces({
    required String businessId,
    required String query,
  }) async {
    return GooglePlacesSearchResponse((b) => b.candidates.addAll([]));
  }

  @override
  Future<void> linkGooglePlace({
    required String businessId,
    required String placeId,
    String? name,
    String? address,
  }) async {}

  @override
  Future<GoogleReviewsSyncResponse> syncGoogleReviews(String businessId) async {
    return GoogleReviewsSyncResponse(
      (b) => b
        ..syncedCount = 0
        ..lastSyncedAt = DateTime.utc(2026, 8, 1)
        ..debounced = false,
    );
  }

  @override
  Future<WhatsAppLinkResponse> createWhatsAppLink(String businessId) async {
    return WhatsAppLinkResponse((b) => b..available = false);
  }

  @override
  Future<List<WhatsAppDraftResponse>> whatsappDrafts(String businessId) async => [];
}

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

class _FakeDashboardRepository extends DashboardRepository with _ParityDashboardStubs {
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
class _RecordingDashboardRepository extends DashboardRepository with _ParityDashboardStubs {
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

List<FeaturedSku> _defaultSkus() => [
      FeaturedSku((b) => b
        ..code = 'featured_7d'
        ..durationDays = 7
        ..listedPriceInr = 299),
      FeaturedSku((b) => b
        ..code = 'featured_15d'
        ..durationDays = 15
        ..listedPriceInr = 499),
      FeaturedSku((b) => b
        ..code = 'featured_30d'
        ..durationDays = 30
        ..listedPriceInr = 899),
    ];

PlacementResponse _notFeaturedPlacement({String businessId = 'biz-1'}) => PlacementResponse((b) => b
  ..businessId = businessId
  ..active = false
  ..awaitingApproval = false
  ..sku.replace(_defaultSkus().first));

PlacementResponse _activePlacement({String businessId = 'biz-1', required DateTime endsAt}) =>
    PlacementResponse((b) => b
      ..businessId = businessId
      ..active = true
      ..awaitingApproval = false
      ..sku.replace(_defaultSkus().first)
      ..placement.replace(PlacementWindow((p) => p
        ..id = 'placement-1'
        ..startsAt = endsAt.subtract(const Duration(days: 7))
        ..endsAt = endsAt
        ..paymentId = 'payment-1')));

PlacementResponse _awaitingApprovalPlacement({String businessId = 'biz-1'}) => PlacementResponse((b) => b
  ..businessId = businessId
  ..active = false
  ..awaitingApproval = true
  ..sku.replace(_defaultSkus().first));

/// S-062/M-66: `PaymentsRepository` fake -- default is the "never featured"
/// state so pre-existing S-060/S-059 tests that render an approved business
/// (and therefore build `FeaturedBoostPanel`) don't hit a real,
/// never-resolving `ApiClient()` network call. Overriding this is what
/// fixed a real `pumpAndSettle` hang introduced when the panel was wired in
/// with no test-provider override (see TR-S-062).
class _FakePaymentsRepository extends PaymentsRepository {
  _FakePaymentsRepository({
    List<FeaturedSku>? skus,
    PlacementResponse? placement,
    this.skusError,
    this.placementError,
  })  : skus = skus ?? _defaultSkus(),
        _placementResponse = placement ?? _notFeaturedPlacement(),
        super(ApiClient());

  final List<FeaturedSku> skus;
  final PlacementResponse _placementResponse;
  final Object? skusError;
  final Object? placementError;
  String? lastCheckoutSku;
  FeaturedCheckoutResponse? checkoutResult;
  Object? checkoutError;

  @override
  Future<List<FeaturedSku>> featuredSkus() async {
    final error = skusError;
    if (error != null) throw error;
    return skus;
  }

  @override
  Future<PlacementResponse> placement(String businessId) async {
    final error = placementError;
    if (error != null) throw error;
    return _placementResponse;
  }

  @override
  Future<FeaturedCheckoutResponse> checkoutFeatured({
    required String businessId,
    required String skuCode,
  }) async {
    lastCheckoutSku = skuCode;
    final error = checkoutError;
    if (error != null) throw error;
    return checkoutResult ??
        FeaturedCheckoutResponse(
          (b) => b
            ..paymentId = 'pay-1'
            ..provider = 'mock'
            ..providerOrderId = 'order-demo'
            ..amountPaise = 29900
            ..currency = 'INR'
            ..sku.replace(_defaultSkus().first)
            ..checkout.replace(
              CheckoutFields(
                (c) => c
                  ..keyId = ''
                  ..orderId = 'order-demo'
                  ..amount = 29900
                  ..currency = 'INR'
                  ..name = 'MerchantHub'
                  ..description = 'Featured',
              ),
            ),
        );
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  List<BusinessResponse> mine = const [],
  DashboardRepository? dashboardRepository,
  PaymentsRepository? paymentsRepository,
}) async {
  // S-060 added a range selector + two fl_chart sections + a reply-rate/CSV
  // row to this screen's ListView -- the default 800x600 test surface is
  // too short to build (and thus find.byKey) content further down the list
  // (e.g. aiInsightsDisclaimer), same class of fix S-058/S-059's Tester
  // documented for other screens.
  await tester.binding.setSurfaceSize(const Size(400, 4200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository(mine)),
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository ?? _FakeDashboardRepository()),
      paymentsRepositoryProvider.overrideWithValue(paymentsRepository ?? _FakePaymentsRepository()),
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

  testWidgets('S-060/S-063 AC6: review volume chart shows empty-state copy when there is no volume data', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: _RecordingDashboardRepository());

    expect(find.byKey(const Key('reviewVolumeChart')), findsOneWidget);
    expect(find.byKey(const Key('reviewVolumeChartEmpty')), findsOneWidget);
    // AC 1/AC 6: the chart-type upgrade (bar -> line/area) must not regress
    // S-060's empty-state behavior -- neither chart type renders at all when
    // every month's count is zero/there's no data.
    expect(find.byType(BarChart), findsNothing);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets(
    'S-063 AC1: review volume chart renders as a LineChart (area/line, not BarChart) when data is present',
    (tester) async {
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
      // S-063/M-68 AC 1: bar -> area/line upgrade of the same series. Rating
      // distribution (unrelated, unchanged S-060 chart) has no data in this
      // stats object either, so it renders its own empty state -- no
      // BarChart anywhere on screen confirms the volume chart itself is no
      // longer a BarChart, not just that *a* LineChart happens to exist.
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    },
  );

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

  testWidgets(
    'S-062 AC1 / S-066: featured boost panel renders live SKU prices as checkout actions',
    (tester) async {
      await _pumpDashboard(tester, mine: [_owned()]);

      expect(find.byKey(const Key('featuredBoostPanel')), findsOneWidget);
      expect(find.text('₹299 / 7 days'), findsOneWidget);
      expect(find.text('₹499 / 15 days'), findsOneWidget);
      expect(find.text('₹899 / 30 days'), findsOneWidget);
      expect(find.byKey(const Key('featuredCheckout-featured_7d')), findsOneWidget);
    },
  );

  testWidgets('S-066 M-66: SKU buttons start checkout and show a mock pending order', (tester) async {
    final payments = _FakePaymentsRepository();
    await _pumpDashboard(tester, mine: [_owned()], paymentsRepository: payments);

    final skuButton = find.byKey(const Key('featuredCheckout-featured_7d'));
    expect(skuButton, findsOneWidget);
    await tester.ensureVisible(skuButton);
    await tester.tap(skuButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(payments.lastCheckoutSku, 'featured_7d');
    expect(find.byKey(const Key('featuredCheckoutPendingNote')), findsOneWidget);
    expect(find.textContaining('Demo order'), findsOneWidget);
  });

  testWidgets('S-062 AC3: placement status shows "Active until <expiry>" when a placement is active', (
    tester,
  ) async {
    final endsAt = DateTime.utc(2026, 9, 1, 12);
    await _pumpDashboard(
      tester,
      mine: [_owned()],
      paymentsRepository: _FakePaymentsRepository(placement: _activePlacement(endsAt: endsAt)),
    );

    final status = find.byKey(const Key('featuredPlacementStatus'));
    expect(status, findsOneWidget);
    expect(tester.widget<Text>(status).data, contains('Active until'));
  });

  testWidgets(
    'S-062 AC4/S-042: a captured-but-unapproved payment shows "awaiting admin approval", never "Active until"',
    (tester) async {
      await _pumpDashboard(
        tester,
        mine: [_owned()],
        paymentsRepository: _FakePaymentsRepository(placement: _awaitingApprovalPlacement()),
      );

      final status = find.byKey(const Key('featuredPlacementStatus'));
      expect(status, findsOneWidget);
      final data = tester.widget<Text>(status).data;
      expect(data, 'Payment received — awaiting admin approval');
      expect(data, isNot(contains('Active until')));
    },
  );

  testWidgets('S-062 AC4: no active or pending placement shows "Not currently featured"', (tester) async {
    await _pumpDashboard(
      tester,
      mine: [_owned()],
      paymentsRepository: _FakePaymentsRepository(placement: _notFeaturedPlacement()),
    );

    final status = find.byKey(const Key('featuredPlacementStatus'));
    expect(tester.widget<Text>(status).data, 'Not currently featured');
  });

  testWidgets('S-062 AC10: featured boost panel is not shown for a pending (not-yet-approved) business', (
    tester,
  ) async {
    await _pumpDashboard(tester, mine: [_owned(status: BusinessStatus.pending)]);

    expect(find.byKey(const Key('featuredBoostPanel')), findsNothing);
  });

  testWidgets('S-062: a placement-fetch failure surfaces the panel\'s own error/retry, not a silent blank panel', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      mine: [_owned()],
      paymentsRepository: _FakePaymentsRepository(placementError: Exception('Network error')),
    );

    final panel = find.byKey(const Key('featuredBoostPanel'));
    expect(panel, findsOneWidget);
    expect(find.descendant(of: panel, matching: find.textContaining('Network error')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.widgetWithText(OutlinedButton, 'Retry')), findsOneWidget);
    expect(find.byKey(const Key('featuredPlacementStatus')), findsNothing);
  });

  testWidgets('S-062: a SKU-catalog fetch failure also surfaces the panel\'s error/retry pattern', (tester) async {
    await _pumpDashboard(
      tester,
      mine: [_owned()],
      paymentsRepository: _FakePaymentsRepository(skusError: Exception('SKU fetch failed')),
    );

    final panel = find.byKey(const Key('featuredBoostPanel'));
    expect(find.descendant(of: panel, matching: find.textContaining('SKU fetch failed')), findsOneWidget);
  });

  testWidgets(
    'S-063 AC3: "All time" range shows no delta badge at all on either tile (fully absent, not an em dash)',
    (tester) async {
      // Default range is 'all' -- no need to tap the selector. previous
      // fields are null on this stats object too (matches the real backend,
      // which nulls both *_previous fields for range=all), but AC 3 must be
      // satisfied by the _range == 'all' short-circuit itself, not by
      // incidentally falling through to the previous == null branch (AC 4) --
      // that's exactly the conflation the Architect flagged in Risks.
      final stats = DashboardStats((b) => b
        ..totalReviews = 4
        ..averageRating = 4.5
        ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})
        ..replyRate = 0.5
        ..reviewCountInRange = 10);

      await _pumpDashboard(
        tester,
        mine: [_owned()],
        dashboardRepository: _RecordingDashboardRepository(stats: stats),
      );

      expect(find.byKey(const Key('replyRateTile')), findsOneWidget);
      expect(find.byKey(const Key('reviewCountInRangeTile')), findsOneWidget);
      expect(find.byKey(const Key('trendDeltaUndefined')), findsNothing);
      expect(find.byKey(const Key('trendDeltaValue')), findsNothing);
    },
  );

  testWidgets(
    'S-063 AC4: 30-day range with a null previous window shows an em dash badge (distinct from AC 3\'s "fully absent")',
    (tester) async {
      final repo = _RecordingDashboardRepository(
        statsByRange: {
          'all': DashboardStats((b) => b
            ..totalReviews = 4
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})),
          '30': DashboardStats((b) => b
            ..totalReviews = 4
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})
            ..replyRate = 0.5
            ..reviewCountInRange = 3),
          // replyRatePrevious / reviewCountPrevious intentionally left null --
          // the "previous window had zero reviews" case.
        },
      );

      await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

      await tester.tap(find.text('Last 30 days'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // AC 4: badge is present (unlike AC 3), but shows an em dash -- never a
      // fabricated percentage.
      expect(find.byKey(const Key('trendDeltaUndefined')), findsNWidgets(2));
      expect(find.byKey(const Key('trendDeltaValue')), findsNothing);
    },
  );

  testWidgets(
    'S-063 (Architect Risks): previous == 0 (a real zero, not null) also renders an em dash, never a fabricated '
    '"infinite"/huge percentage',
    (tester) async {
      final repo = _RecordingDashboardRepository(
        statsByRange: {
          'all': DashboardStats((b) => b
            ..totalReviews = 4
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})),
          '30': DashboardStats((b) => b
            ..totalReviews = 4
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 4, 'neutral': 0, 'negative': 0})
            ..replyRate = 0.5
            ..replyRatePrevious = 0
            ..reviewCountInRange = 6
            ..reviewCountPrevious = 0),
        },
      );

      await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

      await tester.tap(find.text('Last 30 days'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('trendDeltaUndefined')), findsNWidgets(2));
      // `trendDeltaValue` is the only widget that would ever render a
      // percentage for a delta badge -- asserting it's entirely absent locks
      // in "never a fabricated large/infinite percentage" without false-
      // positiving on the tiles' own current-value text (e.g. replyRate's
      // own "50%", which is unrelated to the delta badge).
      expect(find.byKey(const Key('trendDeltaValue')), findsNothing);
    },
  );

  testWidgets(
    'S-063 AC2: delta badge shows +50% up-arrow when current > previous, and -33% down-arrow when current < previous',
    (tester) async {
      final repo = _RecordingDashboardRepository(
        statsByRange: {
          'all': DashboardStats((b) => b
            ..totalReviews = 10
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 10, 'neutral': 0, 'negative': 0})),
          '30': DashboardStats((b) => b
            ..totalReviews = 10
            ..averageRating = 4.5
            ..sentimentBreakdown.addAll({'positive': 10, 'neutral': 0, 'negative': 0})
            // Reply rate: 15% vs previous 10% -> +50% up.
            ..replyRate = 0.15
            ..replyRatePrevious = 0.10
            // Review count in range: 10 vs previous 15 -> -33% down (.round()).
            ..reviewCountInRange = 10
            ..reviewCountPrevious = 15),
        },
      );

      await _pumpDashboard(tester, mine: [_owned()], dashboardRepository: repo);

      await tester.tap(find.text('Last 30 days'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final replyTile = find.byKey(const Key('replyRateTile'));
      expect(find.descendant(of: replyTile, matching: find.byKey(const Key('trendDeltaValue'))), findsOneWidget);
      expect(find.descendant(of: replyTile, matching: find.text('50%')), findsOneWidget);
      expect(
        find.descendant(
          of: replyTile,
          matching: find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.arrow_upward),
        ),
        findsOneWidget,
      );

      final countTile = find.byKey(const Key('reviewCountInRangeTile'));
      expect(find.descendant(of: countTile, matching: find.byKey(const Key('trendDeltaValue'))), findsOneWidget);
      expect(find.descendant(of: countTile, matching: find.text('33%')), findsOneWidget);
      expect(
        find.descendant(
          of: countTile,
          matching: find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.arrow_downward),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('S-066 M-69: benchmark card shows directory medians and disclaimer', (tester) async {
    await _pumpDashboard(tester, mine: [_owned()]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('benchmarkCard')), findsOneWidget);
    expect(find.byKey(const Key('benchmarkDisclaimer')), findsOneWidget);
    expect(find.textContaining('not an AI judgment'), findsOneWidget);
    expect(find.textContaining('Category median'), findsOneWidget);
  });

  testWidgets('S-066 M-78: Common Themes lists topic label, count, and suggestion', (tester) async {
    await _pumpDashboard(tester, mine: [_owned()]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('commonThemesHeading')), findsOneWidget);
    expect(find.textContaining('Wait time'), findsOneWidget);
    expect(find.textContaining('(suggestion)'), findsWidgets);
  });

  testWidgets('S-066 M-80: unlinked Google panel offers Link Google Business Profile', (tester) async {
    await _pumpDashboard(tester, mine: [_owned()]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('googleReviewsPanel')), findsOneWidget);
    expect(find.byKey(const Key('linkGoogleProfileButton')), findsOneWidget);
  });

  testWidgets('S-066 M-79: WhatsApp panel shows suggestion disclaimer when link is unavailable', (tester) async {
    await _pumpDashboard(tester, mine: [_owned()]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('whatsAppUpdatePanel')), findsOneWidget);
    expect(find.byKey(const Key('whatsAppSuggestionDisclaimer')), findsOneWidget);
    expect(find.textContaining('not configured'), findsOneWidget);
  });

  testWidgets('S-093: processing listing shows under-review banner', (tester) async {
    await _pumpDashboard(tester, mine: [_owned(status: BusinessStatus.processing)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('processingUnderReviewBanner')), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
  });
}
