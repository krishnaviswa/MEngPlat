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

UserResponse _merchant() => UserResponse((b) => b
  ..id = 'm-1'
  ..email = 'merchant@example.com'
  ..fullName = 'Mina Merchant'
  ..role = UserRole.merchant
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _owned({String id = 'biz-1', String name = "Mina's Cafe"}) => BusinessResponse((b) => b
  ..id = id
  ..name = name
  ..slug = 'minas-cafe'
  ..address = '1 Main St'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
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
  Future<DashboardStats> merchantStats(String businessId) async {
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

Future<void> _pumpDashboard(WidgetTester tester, {List<BusinessResponse> mine = const []}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository(mine)),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
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
}
