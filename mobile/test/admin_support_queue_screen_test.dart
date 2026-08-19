import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_providers.dart';
import 'package:merchanthub_mobile/features/admin/admin_repository.dart';
import 'package:merchanthub_mobile/features/admin/admin_support_queue_screen.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(ApiClient());

  String? updatedId;
  String? updatedStatus;

  @override
  Future<List<SupportTicketResponse>> listSupportTickets({String? status}) async {
    return [
      SupportTicketResponse((b) => b
        ..id = 't-1'
        ..name = 'Casey'
        ..phone = '5551234567'
        ..issue = 'Cannot reset password on mobile'
        ..status = 'open'
        ..createdAt = DateTime.utc(2026, 1, 1)
        ..updatedAt = DateTime.utc(2026, 1, 1)),
    ];
  }

  @override
  Future<SupportTicketResponse> updateSupportTicket({
    required String ticketId,
    String? status,
    String? adminResponse,
  }) async {
    updatedId = ticketId;
    updatedStatus = status;
    return SupportTicketResponse((b) => b
      ..id = ticketId
      ..name = 'Casey'
      ..phone = '5551234567'
      ..issue = 'Cannot reset password on mobile'
      ..status = status ?? 'open'
      ..createdAt = DateTime.utc(2026, 1, 1)
      ..updatedAt = DateTime.utc(2026, 1, 1));
  }
}

void main() {
  testWidgets('S-094: admin support queue lists tickets and Admin back exists', (tester) async {
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(_FakeAdminRepository())],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/admin/support',
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const Scaffold(body: Text('ADMIN_HOME'))),
        GoRoute(path: '/admin/support', builder: (context, state) => const AdminSupportQueueScreen()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminSupportQueueScreen')), findsOneWidget);
    expect(find.textContaining('Casey'), findsOneWidget);
    expect(find.byKey(const Key('adminBackLink')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adminBackLink')));
    await tester.pumpAndSettle();
    expect(find.text('ADMIN_HOME'), findsOneWidget);
  });
}
