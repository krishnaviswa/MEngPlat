import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for NotificationsApi
void main() {
  final instance = MerchanthubApi().getNotificationsApi();

  group(NotificationsApi, () {
    // List Notifications
    //
    // List notifications for the current user.  **Query:** unread_only (default false) **Response:** Array of notifications ordered by created_at desc
    //
    //Future<BuiltList<NotificationResponse>> listNotificationsApiV1NotificationsGet({ bool unreadOnly }) async
    test('test listNotificationsApiV1NotificationsGet', () async {
      // TODO
    });

    // Mark All Read
    //
    // Mark all notifications as read for current user.
    //
    //Future<MessageResponse> markAllReadApiV1NotificationsReadAllPost() async
    test('test markAllReadApiV1NotificationsReadAllPost', () async {
      // TODO
    });

    // Mark Read
    //
    // Mark a single notification as read.
    //
    //Future<MessageResponse> markReadApiV1NotificationsNotificationIdReadPost(String notificationId) async
    test('test markReadApiV1NotificationsNotificationIdReadPost', () async {
      // TODO
    });

  });
}
