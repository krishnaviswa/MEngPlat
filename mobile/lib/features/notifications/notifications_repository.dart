import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final ApiClient _client;

  /// Newest first (backend ordering), capped at 50 server-side.
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async {
    try {
      final response = await _client.api.getNotificationsApi().listNotificationsApiV1NotificationsGet(
            unreadOnly: unreadOnly,
          );
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _client.api.getNotificationsApi().markReadApiV1NotificationsNotificationIdReadPost(
            notificationId: notificationId,
          );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.api.getNotificationsApi().markAllReadApiV1NotificationsReadAllPost();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
