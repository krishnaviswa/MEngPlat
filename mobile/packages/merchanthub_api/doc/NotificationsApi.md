# merchanthub_api.api.NotificationsApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listNotificationsApiV1NotificationsGet**](NotificationsApi.md#listnotificationsapiv1notificationsget) | **GET** /api/v1/notifications | List Notifications
[**markAllReadApiV1NotificationsReadAllPost**](NotificationsApi.md#markallreadapiv1notificationsreadallpost) | **POST** /api/v1/notifications/read-all | Mark All Read
[**markReadApiV1NotificationsNotificationIdReadPost**](NotificationsApi.md#markreadapiv1notificationsnotificationidreadpost) | **POST** /api/v1/notifications/{notification_id}/read | Mark Read


# **listNotificationsApiV1NotificationsGet**
> BuiltList<NotificationResponse> listNotificationsApiV1NotificationsGet(unreadOnly)

List Notifications

List notifications for the current user.  **Query:** unread_only (default false) **Response:** Array of notifications ordered by created_at desc

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getNotificationsApi();
final bool unreadOnly = true; // bool | 

try {
    final response = api.listNotificationsApiV1NotificationsGet(unreadOnly);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->listNotificationsApiV1NotificationsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **unreadOnly** | **bool**|  | [optional] [default to false]

### Return type

[**BuiltList&lt;NotificationResponse&gt;**](NotificationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllReadApiV1NotificationsReadAllPost**
> MessageResponse markAllReadApiV1NotificationsReadAllPost()

Mark All Read

Mark all notifications as read for current user.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getNotificationsApi();

try {
    final response = api.markAllReadApiV1NotificationsReadAllPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->markAllReadApiV1NotificationsReadAllPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markReadApiV1NotificationsNotificationIdReadPost**
> MessageResponse markReadApiV1NotificationsNotificationIdReadPost(notificationId)

Mark Read

Mark a single notification as read.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getNotificationsApi();
final String notificationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.markReadApiV1NotificationsNotificationIdReadPost(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->markReadApiV1NotificationsNotificationIdReadPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **String**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

