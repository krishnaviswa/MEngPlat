import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_home_screen.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/merchant/dashboard_repository.dart';
import 'package:merchanthub_mobile/features/merchant/merchant_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

UserResponse _admin() => UserResponse((b) => b
  ..id = 'a-1'
  ..email = 'admin@example.com'
  ..fullName = 'Ada Admin'
  ..role = UserRole.admin
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _admin();
}

class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository() : super(ApiClient());

  final daysRequested = <int>[];

  @override
  Future<PlatformAnalytics> platformAnalytics() async {
    return PlatformAnalytics((b) => b
      ..totalUsers = 10
      ..totalBusinesses = 4
      ..pendingBusinesses = 1
      ..totalReviews = 8
      ..reportedReviews = 0);
  }

  @override
  Future<PlatformAnalyticsSeries> platformAnalyticsSeries({int days = 90}) async {
    daysRequested.add(days);
    return PlatformAnalyticsSeries((b) => b
      ..granularity = PlatformAnalyticsSeriesGranularityEnum.day
      ..days = days);
  }
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listByStatus(BusinessStatus status) async => [];
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());

  @override
  Future<List<ReviewResponse>> listReported() async => [];
}

Future<void> _tallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('S-061 AC2: the chart row renders below the stat tiles, not above/instead of them', (tester) async {
    await _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Empty series -> the empty-chart treatment (AC3), but it must still sit
    // between the stat tiles and "Pending businesses" per AC2.
    final statsY = tester.getBottomLeft(find.text('Total users')).dy;
    final chartY = tester.getTopLeft(find.byKey(const Key('platformSeriesEmpty'))).dy;
    final pendingY = tester.getTopLeft(find.byKey(const Key('pendingQueueHeading'))).dy;
    expect(statsY, lessThan(chartY));
    expect(chartY, lessThan(pendingY));
  });

  testWidgets('S-061 AC4: no chart or stat-tile copy frames this data as AI output', (tester) async {
    await _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('suggestion'), findsNothing);
    expect(find.textContaining('AI:'), findsNothing);
  });

  testWidgets('S-061: "Manage categories" and "Total users" tile navigate to the two new admin sub-routes',
      (tester) async {
    await _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
        GoRoute(path: '/admin/categories', builder: (context, state) => const Scaffold(body: Text('CATEGORIES_SCREEN'))),
        GoRoute(path: '/admin/users', builder: (context, state) => const Scaffold(body: Text('USERS_SCREEN'))),
        GoRoute(path: '/admin/whatsapp', builder: (context, state) => const Scaffold(body: Text('WHATSAPP_SCREEN'))),
        GoRoute(path: '/admin/support', builder: (context, state) => const Scaffold(body: Text('SUPPORT_SCREEN'))),
        GoRoute(path: '/admin/business-reports', builder: (context, state) => const Scaffold(body: Text('REPORTS_SCREEN'))),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('manageCategoriesButton')));
    await tester.tap(find.byKey(const Key('manageCategoriesButton')));
    await tester.pumpAndSettle();
    expect(find.text('CATEGORIES_SCREEN'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Total users'));
    await tester.tap(find.text('Total users'));
    await tester.pumpAndSettle();
    expect(find.text('USERS_SCREEN'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manageWhatsAppDraftsButton')));
    await tester.tap(find.byKey(const Key('manageWhatsAppDraftsButton')));
    await tester.pumpAndSettle();
    expect(find.text('WHATSAPP_SCREEN'), findsOneWidget);
  });

  testWidgets('platform trends range 7d refetches series with days=7', (tester) async {
    await _tallSurface(tester);
    final dash = _FakeDashboardRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(dash),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(dash.daysRequested, [90]);
    await tester.ensureVisible(find.byKey(const Key('platformSeriesRange')));
    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();
    expect(dash.daysRequested, [90, 7]);
  });

  testWidgets('S-031 AC16: admin home shows platform stats, not the web placeholder', (tester) async {
    await _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);
    expect(find.text('Total users'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('No businesses awaiting review'), findsOneWidget);
    expect(find.textContaining('on the web for now'), findsNothing);
  });

  testWidgets('S-093: pending and processing listings share a queue with start/return actions', (tester) async {
    await _tallSurface(tester);
    final pending = BusinessResponse((b) => b
      ..id = 'p-1'
      ..name = 'Pending Shop'
      ..slug = 'pending-shop'
      ..address = '1 Main'
      ..city = 'X'
      ..country = 'IN'
      ..status = BusinessStatus.pending
      ..averageRating = 0
      ..reviewCount = 0);
    final processing = pending.rebuild((b) => b
      ..id = 'pr-1'
      ..name = 'Processing Shop'
      ..slug = 'processing-shop'
      ..status = BusinessStatus.processing);

    final repo = _QueueBusinessRepository(pending: [pending], processing: [processing]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(repo),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: AdminHomeScreen())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pending Shop'), findsOneWidget);
    expect(find.text('Processing Shop'), findsOneWidget);
    expect(find.byKey(const Key('startReview-p-1')), findsOneWidget);
    expect(find.byKey(const Key('returnToPending-pr-1')), findsOneWidget);
    expect(find.byKey(const Key('startReview-pr-1')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('startReview-p-1')));
    await tester.tap(find.byKey(const Key('startReview-p-1')));
    await tester.pumpAndSettle();
    expect(repo.started, ['p-1']);

    final startDy = tester.getCenter(find.byKey(const Key('startReview-p-1'))).dy;
    final approveDy = tester.getCenter(find.byKey(const Key('approveBusiness-p-1'))).dy;
    final suspendDy = tester.getCenter(find.byKey(const Key('suspendBusiness-p-1'))).dy;
    expect((startDy - approveDy).abs(), lessThan(2));
    expect((approveDy - suspendDy).abs(), lessThan(2));
  });

  testWidgets('pending queue name opens the public business profile', (tester) async {
    await _tallSurface(tester);
    final pending = BusinessResponse((b) => b
      ..id = 'p-1'
      ..name = 'Pending Shop'
      ..slug = 'pending-shop'
      ..address = '1 Main'
      ..city = 'X'
      ..country = 'IN'
      ..status = BusinessStatus.pending
      ..averageRating = 0
      ..reviewCount = 0);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_QueueBusinessRepository(pending: [pending], processing: [])),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
        GoRoute(
          path: '/businesses/:slug',
          builder: (context, state) => Scaffold(body: Text('OPENED_${state.pathParameters['slug']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('openQueueBusiness-p-1')));
    await tester.tap(find.byKey(const Key('openQueueBusiness-p-1')));
    await tester.pumpAndSettle();
    expect(find.text('OPENED_pending-shop'), findsOneWidget);
  });

  testWidgets('S-095: extra ops tiles and nav chips are present', (tester) async {
    await _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
        reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: AdminHomeScreen())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('adminOpsNav')), findsOneWidget);
    expect(find.byKey(const Key('dashboardHubScaffold')), findsOneWidget);
    expect(find.byKey(const Key('openSupportTicketsTile')), findsOneWidget);
    expect(find.byKey(const Key('repeatShopReportsTile')), findsOneWidget);
    expect(find.byKey(const Key('processingBusinessesTile')), findsOneWidget);
  });
}

class _QueueBusinessRepository extends BusinessRepository {
  _QueueBusinessRepository({required this.pending, required this.processing}) : super(ApiClient());

  List<BusinessResponse> pending;
  List<BusinessResponse> processing;
  final started = <String>[];

  @override
  Future<List<BusinessResponse>> listByStatus(BusinessStatus status) async {
    if (status == BusinessStatus.pending) return pending;
    if (status == BusinessStatus.processing) return processing;
    return [];
  }

  @override
  Future<BusinessResponse> startReview(String businessId) async {
    started.add(businessId);
    return pending.firstWhere((b) => b.id == businessId).rebuild((b) => b.status = BusinessStatus.processing);
  }
}
