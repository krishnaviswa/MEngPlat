import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// User-account moderation (M-64, S-061). A distinct concern from
/// [DashboardRepository] (analytics) and `BusinessRepository` (business
/// CRUD/search) -- no existing repository owned this.
class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  Future<List<UserResponse>> listUsers() async {
    try {
      final response = await _client.api.getAdminApi().listUsersApiV1AdminUsersGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserResponse> suspendUser(String userId) async {
    try {
      final response = await _client.api.getAdminApi().suspendUserApiV1AdminUsersUserIdSuspendPost(userId: userId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserResponse> reactivateUser(String userId) async {
    try {
      final response = await _client.api.getAdminApi().reactivateUserApiV1AdminUsersUserIdReactivatePost(userId: userId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminWhatsAppDraftQueueResponse> listWhatsAppDrafts({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.api.getAdminApi().listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet(
        page: page,
        pageSize: pageSize,
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<WhatsAppDraftResponse> approveWhatsAppDraft(String draftId, {JsonObject? fields}) async {
    try {
      final response = await _client.api.getAdminApi().approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost(
        draftId: draftId,
        adminWhatsAppDraftApproveRequest: fields == null
            ? null
            : AdminWhatsAppDraftApproveRequest((b) => b.fields = fields),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<WhatsAppDraftResponse> rejectWhatsAppDraft(String draftId) async {
    try {
      final response = await _client.api
          .getAdminApi()
          .rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost(draftId: draftId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
