import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for AdminApi
void main() {
  final instance = MerchanthubApi().getAdminApi();

  group(AdminApi, () {
    // Approve Admin Whatsapp Draft
    //
    // Admin: approve a WhatsApp draft, writing the (optionally edited) fields to the live Business row. Omitted/absent fields fall back to the raw AI extraction. `404` unknown draft; `409` already resolved (S-053).
    //
    //Future<WhatsAppDraftResponse> approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost(String draftId, { AdminWhatsAppDraftApproveRequest adminWhatsAppDraftApproveRequest }) async
    test('test approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost', () async {
      // TODO
    });

    // List Admin Whatsapp Drafts
    //
    // Admin: global, cross-business queue of pending WhatsApp-derived profile drafts, oldest first (S-053). This is the sole surface a WhatsApp draft can be approved or rejected from -- merchants can view but no longer act.
    //
    //Future<AdminWhatsAppDraftQueueResponse> listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet({ int page, int pageSize }) async
    test('test listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet', () async {
      // TODO
    });

    // List Users
    //
    // Admin: list all users, newest `created_at` first.  **Query:** page (default 1), page_size (default 20, cap 100), optional `q` substring match on email or full_name (case-insensitive). **Response:** never includes `totp_secret`, `hashed_password`, or `google_sub`.
    //
    //Future<BuiltList<UserResponse>> listUsersApiV1AdminUsersGet({ int page, int pageSize, String q }) async
    test('test listUsersApiV1AdminUsersGet', () async {
      // TODO
    });

    // Reactivate User
    //
    // Admin: reactivate a non-admin user (`is_active=true`) and record an AuditLog row. Idempotent if already active. Refused (400) for the caller's own account or another admin.
    //
    //Future<UserResponse> reactivateUserApiV1AdminUsersUserIdReactivatePost(String userId) async
    test('test reactivateUserApiV1AdminUsersUserIdReactivatePost', () async {
      // TODO
    });

    // Reject Admin Whatsapp Draft
    //
    // Admin: reject a WhatsApp draft. The live Business row is left untouched (S-053).
    //
    //Future<WhatsAppDraftResponse> rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost(String draftId) async
    test('test rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost', () async {
      // TODO
    });

    // Suspend User
    //
    // Admin: suspend a non-admin user (`is_active=false`) and record an AuditLog row. Idempotent if already inactive. Refused (400) for the caller's own account or another admin.
    //
    //Future<UserResponse> suspendUserApiV1AdminUsersUserIdSuspendPost(String userId) async
    test('test suspendUserApiV1AdminUsersUserIdSuspendPost', () async {
      // TODO
    });

  });
}
