import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/admin/admin_providers.dart';
import 'package:merchanthub_mobile/features/admin/admin_repository.dart';
import 'package:merchanthub_mobile/features/admin/admin_whatsapp_queue_screen.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({this.items = const []}) : super(ApiClient());

  final List<AdminWhatsAppDraftResponse> items;
  String? approvedId;
  String? rejectedId;

  @override
  Future<AdminWhatsAppDraftQueueResponse> listWhatsAppDrafts({int page = 1, int pageSize = 20}) async {
    return AdminWhatsAppDraftQueueResponse(
      (b) => b
        ..items.addAll(items)
        ..total = items.length
        ..page = page
        ..pageSize = pageSize,
    );
  }

  @override
  Future<WhatsAppDraftResponse> approveWhatsAppDraft(String draftId, {JsonObject? fields}) async {
    approvedId = draftId;
    return WhatsAppDraftResponse(
      (b) => b
        ..id = draftId
        ..source_ = 'whatsapp'
        ..extractedFields = JsonObject({'description': 'ok'})
        ..status = DraftStatus.applied
        ..createdAt = DateTime.utc(2026, 8, 1),
    );
  }

  @override
  Future<WhatsAppDraftResponse> rejectWhatsAppDraft(String draftId) async {
    rejectedId = draftId;
    return WhatsAppDraftResponse(
      (b) => b
        ..id = draftId
        ..source_ = 'whatsapp'
        ..extractedFields = JsonObject({'description': 'ok'})
        ..status = DraftStatus.discarded
        ..createdAt = DateTime.utc(2026, 8, 1),
    );
  }
}

AdminWhatsAppDraftResponse _draft() => AdminWhatsAppDraftResponse(
      (b) => b
        ..id = 'draft-1'
        ..source_ = 'whatsapp'
        ..extractedFields = JsonObject({'description': 'Cozy cafe by the park'})
        ..status = DraftStatus.pending
        ..createdAt = DateTime.utc(2026, 8, 1)
        ..businessId = 'biz-1'
        ..businessName = "Mina's Cafe",
    );

void main() {
  testWidgets('S-066 M-79: empty queue copy', (tester) async {
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(_FakeAdminRepository())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminWhatsAppQueueScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('whatsAppQueueEmpty')), findsOneWidget);
  });

  testWidgets('S-066 M-79: admin can approve or reject a pending draft', (tester) async {
    final repo = _FakeAdminRepository(items: [_draft()]);
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminWhatsAppQueueScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('whatsAppDraft-draft-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('approveWhatsApp-draft-1')));
    await tester.pump();
    await tester.pump();
    expect(repo.approvedId, 'draft-1');
    expect(find.byKey(const Key('whatsAppDraft-draft-1')), findsNothing);
  });
}
