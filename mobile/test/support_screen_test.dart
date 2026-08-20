import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/support/support_repository.dart';
import 'package:merchanthub_mobile/features/support/support_screen.dart';
import 'package:merchanthub_mobile/features/support/support_ticket_detail_screen.dart';
import 'package:merchanthub_mobile/features/support/ticket_ref.dart';

const _ticketId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

UserResponse _user() => UserResponse((b) => b
  ..id = 'u-1'
  ..email = 'c@example.com'
  ..fullName = 'Casey'
  ..phone = '5551234567'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

SupportTicketResponse _ticket({
  String id = _ticketId,
  String issue = 'Need help with my listing please',
  String? adminResponse,
}) {
  return SupportTicketResponse((b) => b
    ..id = id
    ..name = 'Casey'
    ..phone = '5551234567'
    ..issue = issue
    ..status = 'open'
    ..adminResponse = adminResponse
    ..createdAt = DateTime.utc(2026, 1, 1)
    ..updatedAt = DateTime.utc(2026, 1, 1));
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);
  final UserResponse? user;

  @override
  Future<UserResponse?> build() async => user;
}

class _FakeSupportRepository extends SupportRepository {
  _FakeSupportRepository({List<SupportTicketResponse>? tickets}) : super(ApiClient()) {
    this.tickets = tickets ?? [];
  }

  SupportTicketCreate? lastCreate;
  List<SupportTicketResponse> tickets = [];

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
  Future<List<SupportTicketResponse>> myTickets() async => tickets;

  @override
  Future<SupportTicketResponse> getTicket(String ticketId) async {
    return tickets.firstWhere((t) => t.id == ticketId);
  }

  @override
  Future<List<BusinessReportResponse>> myReports() async => [];
}

Future<void> _pumpSupport(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  final router = GoRouter(
    initialLocation: '/support',
    routes: [
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => SupportTicketDetailScreen(ticketId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );

  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('supportTicketRef prefixes MH- and uppercases the first 8 of the UUID', () {
    expect(supportTicketRef(_ticketId), 'MH-AAAAAAAA');
  });

  testWidgets('S-094: support shows contact email and submits a ticket', (tester) async {
    final repo = _FakeSupportRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user())),
        supportRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _pumpSupport(tester, container: container);

    expect(find.byKey(const Key('supportContactEmail')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('supportIssueField')), 'Need help with my listing please');
    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    expect(repo.lastCreate?.issue, 'Need help with my listing please');
    expect(find.byKey(const Key('supportTicketSuccess')), findsOneWidget);
    expect(find.textContaining('MH-TICKET-'), findsOneWidget);
  });

  testWidgets('S-108: tapping a history row opens ticket detail', (tester) async {
    final repo = _FakeSupportRepository(
      tickets: [_ticket(adminResponse: 'We are looking into this.')],
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user())),
        supportRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _pumpSupport(tester, container: container);

    final row = find.byKey(const Key('supportTicket-$_ticketId'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supportTicketDetail')), findsOneWidget);
    expect(find.byKey(const Key('supportTicketRef')), findsOneWidget);
    expect(find.text('MH-AAAAAAAA'), findsOneWidget);
    expect(find.text('Status: open'), findsOneWidget);
    expect(find.text('Need help with my listing please'), findsOneWidget);
    expect(find.text('We are looking into this.'), findsOneWidget);
  });
}
