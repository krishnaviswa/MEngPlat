import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for SupportApi
void main() {
  final instance = MerchanthubApi().getSupportApi();

  group(SupportApi, () {
    // Add Report Message
    //
    //Future<BusinessReportMessageResponse> addReportMessageApiV1BusinessReportsReportIdMessagesPost(String reportId, BusinessReportMessageCreate businessReportMessageCreate) async
    test('test addReportMessageApiV1BusinessReportsReportIdMessagesPost', () async {
      // TODO
    });

    // Create Support Ticket
    //
    // Create a support ticket. Auth optional; logged-in users can later list via /mine.
    //
    //Future<SupportTicketResponse> createSupportTicketApiV1SupportTicketsPost(SupportTicketCreate supportTicketCreate) async
    test('test createSupportTicketApiV1SupportTicketsPost', () async {
      // TODO
    });

    // List My Business Reports
    //
    //Future<BuiltList<BusinessReportResponse>> listMyBusinessReportsApiV1BusinessReportsMineGet() async
    test('test listMyBusinessReportsApiV1BusinessReportsMineGet', () async {
      // TODO
    });

    // List My Support Tickets
    //
    //Future<BuiltList<SupportTicketResponse>> listMySupportTicketsApiV1SupportTicketsMineGet() async
    test('test listMySupportTicketsApiV1SupportTicketsMineGet', () async {
      // TODO
    });

    // Support Contact
    //
    // Public support email for footer / contact page (S-087).
    //
    //Future<SupportContactResponse> supportContactApiV1SupportContactGet() async
    test('test supportContactApiV1SupportContactGet', () async {
      // TODO
    });

  });
}
