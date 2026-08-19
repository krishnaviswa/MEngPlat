import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_business_reports_screen.dart';
import 'package:merchanthub_mobile/features/admin/admin_providers.dart';
import 'package:merchanthub_mobile/features/admin/admin_repository.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(ApiClient());

  @override
  Future<List<BusinessReportResponse>> listBusinessReports({String? status}) async {
    return [
      BusinessReportResponse((b) => b
        ..id = 'r-1'
        ..businessId = 'b-1'
        ..reporterId = 'u-1'
        ..reason = 'Spam listing with fake reviews'
        ..status = 'open'
        ..createdAt = DateTime.utc(2026, 1, 1)
        ..updatedAt = DateTime.utc(2026, 1, 1)
        ..businessName = 'Spam Shop'
        ..isRepeat = true
        ..reportCount = 4),
    ];
  }
}

void main() {
  testWidgets('S-094: shop report queue shows repeat flag', (tester) async {
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(_FakeAdminRepository())],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/admin/business-reports',
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const Scaffold(body: Text('ADMIN_HOME'))),
        GoRoute(path: '/admin/business-reports', builder: (context, state) => const AdminBusinessReportsScreen()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminBusinessReportsScreen')), findsOneWidget);
    expect(find.byKey(const Key('repeatReport-r-1')), findsOneWidget);
    expect(find.textContaining('Repeat shop'), findsOneWidget);
  });
}
