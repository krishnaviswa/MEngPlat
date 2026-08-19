import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/support/support_repository.dart';
import 'package:merchanthub_mobile/features/support/support_screen.dart';

UserResponse _user() => UserResponse((b) => b
  ..id = 'u-1'
  ..email = 'c@example.com'
  ..fullName = 'Casey'
  ..phone = '5551234567'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);
  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeSupportRepository extends SupportRepository {
  _FakeSupportRepository() : super(ApiClient());

  SupportTicketCreate? lastCreate;

  @override
  Future<SupportContactResponse> contact() async =>
      SupportContactResponse((b) => b..email = 'support@merchanthub.example');

  @override
  Future<SupportTicketResponse> createTicket({
    required String name,
    required String phone,
    required String issue,
    String? businessId,
  }) async {
    lastCreate = SupportTicketCreate((b) => b
      ..name = name
      ..phone = phone
      ..issue = issue
      ..businessId = businessId);
    return SupportTicketResponse((b) => b
      ..id = 'ticket-abcdef12'
      ..name = name
      ..phone = phone
      ..issue = issue
      ..status = 'open'
      ..createdAt = DateTime.utc(2026, 1, 1)
      ..updatedAt = DateTime.utc(2026, 1, 1));
  }

  @override
  Future<List<SupportTicketResponse>> myTickets() async => [];

  @override
  Future<List<BusinessReportResponse>> myReports() async => [];
}

void main() {
  testWidgets('S-094: support shows contact email and submits a ticket', (tester) async {
    final repo = _FakeSupportRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user())),
        supportRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: SupportScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supportContactEmail')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('supportIssueField')), 'Need help with my listing please');
    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    expect(repo.lastCreate?.issue, 'Need help with my listing please');
    expect(find.byKey(const Key('supportTicketSuccess')), findsOneWidget);
  });
}
