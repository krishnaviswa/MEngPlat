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
  Future<PlatformAnalyticsSeries> platformAnalyticsSeries() async {
    return PlatformAnalyticsSeries((b) => b
      ..granularity = PlatformAnalyticsSeriesGranularityEnum.day
      ..days = 90);
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

void main() {
  testWidgets('S-061 AC2: the chart row renders below the stat tiles, not above/instead of them', (tester) async {
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
    final pendingY = tester.getTopLeft(find.text('Pending businesses').last).dy;
    expect(statsY, lessThan(chartY));
    expect(chartY, lessThan(pendingY));
  });

  testWidgets('S-061 AC4: no chart or stat-tile copy frames this data as AI output', (tester) async {
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

  testWidgets('S-031 AC16: admin home shows platform stats, not the web placeholder', (tester) async {
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
    expect(find.text('No pending businesses'), findsOneWidget);
    expect(find.textContaining('on the web for now'), findsNothing);
  });
}
