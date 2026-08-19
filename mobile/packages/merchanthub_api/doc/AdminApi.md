# merchanthub_api.api.AdminApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminAddBusinessReportMessageApiV1AdminBusinessReportsReportIdMessagesPost**](AdminApi.md#adminaddbusinessreportmessageapiv1adminbusinessreportsreportidmessagespost) | **POST** /api/v1/admin/business-reports/{report_id}/messages | Admin Add Business Report Message
[**adminListBusinessReportsApiV1AdminBusinessReportsGet**](AdminApi.md#adminlistbusinessreportsapiv1adminbusinessreportsget) | **GET** /api/v1/admin/business-reports | Admin List Business Reports
[**adminListSupportTicketsApiV1AdminSupportTicketsGet**](AdminApi.md#adminlistsupportticketsapiv1adminsupportticketsget) | **GET** /api/v1/admin/support-tickets | Admin List Support Tickets
[**adminUpdateBusinessReportApiV1AdminBusinessReportsReportIdPatch**](AdminApi.md#adminupdatebusinessreportapiv1adminbusinessreportsreportidpatch) | **PATCH** /api/v1/admin/business-reports/{report_id} | Admin Update Business Report
[**adminUpdateSupportTicketApiV1AdminSupportTicketsTicketIdPatch**](AdminApi.md#adminupdatesupportticketapiv1adminsupportticketsticketidpatch) | **PATCH** /api/v1/admin/support-tickets/{ticket_id} | Admin Update Support Ticket
[**approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost**](AdminApi.md#approveadminwhatsappdraftapiv1adminwhatsappdraftsdraftidapprovepost) | **POST** /api/v1/admin/whatsapp/drafts/{draft_id}/approve | Approve Admin Whatsapp Draft
[**listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet**](AdminApi.md#listadminwhatsappdraftsapiv1adminwhatsappdraftsget) | **GET** /api/v1/admin/whatsapp/drafts | List Admin Whatsapp Drafts
[**listUsersApiV1AdminUsersGet**](AdminApi.md#listusersapiv1adminusersget) | **GET** /api/v1/admin/users | List Users
[**reactivateUserApiV1AdminUsersUserIdReactivatePost**](AdminApi.md#reactivateuserapiv1adminusersuseridreactivatepost) | **POST** /api/v1/admin/users/{user_id}/reactivate | Reactivate User
[**rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost**](AdminApi.md#rejectadminwhatsappdraftapiv1adminwhatsappdraftsdraftidrejectpost) | **POST** /api/v1/admin/whatsapp/drafts/{draft_id}/reject | Reject Admin Whatsapp Draft
[**suspendUserApiV1AdminUsersUserIdSuspendPost**](AdminApi.md#suspenduserapiv1adminusersuseridsuspendpost) | **POST** /api/v1/admin/users/{user_id}/suspend | Suspend User


# **adminAddBusinessReportMessageApiV1AdminBusinessReportsReportIdMessagesPost**
> BusinessReportMessageResponse adminAddBusinessReportMessageApiV1AdminBusinessReportsReportIdMessagesPost(reportId, businessReportMessageCreate)

Admin Add Business Report Message

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String reportId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final BusinessReportMessageCreate businessReportMessageCreate = ; // BusinessReportMessageCreate | 

try {
    final response = api.adminAddBusinessReportMessageApiV1AdminBusinessReportsReportIdMessagesPost(reportId, businessReportMessageCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminAddBusinessReportMessageApiV1AdminBusinessReportsReportIdMessagesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reportId** | **String**|  | 
 **businessReportMessageCreate** | [**BusinessReportMessageCreate**](BusinessReportMessageCreate.md)|  | 

### Return type

[**BusinessReportMessageResponse**](BusinessReportMessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListBusinessReportsApiV1AdminBusinessReportsGet**
> BuiltList<BusinessReportResponse> adminListBusinessReportsApiV1AdminBusinessReportsGet(status)

Admin List Business Reports

Admin: shop-level reports with per-shop counts and repeat flag (S-089).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String status = status_example; // String | 

try {
    final response = api.adminListBusinessReportsApiV1AdminBusinessReportsGet(status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminListBusinessReportsApiV1AdminBusinessReportsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 

### Return type

[**BuiltList&lt;BusinessReportResponse&gt;**](BusinessReportResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListSupportTicketsApiV1AdminSupportTicketsGet**
> BuiltList<SupportTicketResponse> adminListSupportTicketsApiV1AdminSupportTicketsGet(status)

Admin List Support Tickets

Admin: all support tickets, oldest first (S-088).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String status = status_example; // String | 

try {
    final response = api.adminListSupportTicketsApiV1AdminSupportTicketsGet(status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminListSupportTicketsApiV1AdminSupportTicketsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 

### Return type

[**BuiltList&lt;SupportTicketResponse&gt;**](SupportTicketResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateBusinessReportApiV1AdminBusinessReportsReportIdPatch**
> BusinessReportResponse adminUpdateBusinessReportApiV1AdminBusinessReportsReportIdPatch(reportId, businessReportAdminUpdate)

Admin Update Business Report

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String reportId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final BusinessReportAdminUpdate businessReportAdminUpdate = ; // BusinessReportAdminUpdate | 

try {
    final response = api.adminUpdateBusinessReportApiV1AdminBusinessReportsReportIdPatch(reportId, businessReportAdminUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminUpdateBusinessReportApiV1AdminBusinessReportsReportIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reportId** | **String**|  | 
 **businessReportAdminUpdate** | [**BusinessReportAdminUpdate**](BusinessReportAdminUpdate.md)|  | 

### Return type

[**BusinessReportResponse**](BusinessReportResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateSupportTicketApiV1AdminSupportTicketsTicketIdPatch**
> SupportTicketResponse adminUpdateSupportTicketApiV1AdminSupportTicketsTicketIdPatch(ticketId, supportTicketAdminUpdate)

Admin Update Support Ticket

Admin: set ticket status and/or response (S-088).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String ticketId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final SupportTicketAdminUpdate supportTicketAdminUpdate = ; // SupportTicketAdminUpdate | 

try {
    final response = api.adminUpdateSupportTicketApiV1AdminSupportTicketsTicketIdPatch(ticketId, supportTicketAdminUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminUpdateSupportTicketApiV1AdminSupportTicketsTicketIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ticketId** | **String**|  | 
 **supportTicketAdminUpdate** | [**SupportTicketAdminUpdate**](SupportTicketAdminUpdate.md)|  | 

### Return type

[**SupportTicketResponse**](SupportTicketResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost**
> WhatsAppDraftResponse approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost(draftId, adminWhatsAppDraftApproveRequest)

Approve Admin Whatsapp Draft

Admin: approve a WhatsApp draft, writing the (optionally edited) fields to the live Business row. Omitted/absent fields fall back to the raw AI extraction. `404` unknown draft; `409` already resolved (S-053).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String draftId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminWhatsAppDraftApproveRequest adminWhatsAppDraftApproveRequest = ; // AdminWhatsAppDraftApproveRequest | 

try {
    final response = api.approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost(draftId, adminWhatsAppDraftApproveRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->approveAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdApprovePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **draftId** | **String**|  | 
 **adminWhatsAppDraftApproveRequest** | [**AdminWhatsAppDraftApproveRequest**](AdminWhatsAppDraftApproveRequest.md)|  | [optional] 

### Return type

[**WhatsAppDraftResponse**](WhatsAppDraftResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet**
> AdminWhatsAppDraftQueueResponse listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet(page, pageSize)

List Admin Whatsapp Drafts

Admin: global, cross-business queue of pending WhatsApp-derived profile drafts, oldest first (S-053). This is the sole surface a WhatsApp draft can be approved or rejected from -- merchants can view but no longer act.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet(page, pageSize);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->listAdminWhatsappDraftsApiV1AdminWhatsappDraftsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]

### Return type

[**AdminWhatsAppDraftQueueResponse**](AdminWhatsAppDraftQueueResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUsersApiV1AdminUsersGet**
> BuiltList<UserResponse> listUsersApiV1AdminUsersGet(page, pageSize, q)

List Users

Admin: list all users, newest `created_at` first.  **Query:** page (default 1), page_size (default 20, cap 100), optional `q` substring match on email or full_name (case-insensitive). **Response:** never includes `totp_secret`, `hashed_password`, or `google_sub`.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 
final String q = q_example; // String | 

try {
    final response = api.listUsersApiV1AdminUsersGet(page, pageSize, q);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->listUsersApiV1AdminUsersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]
 **q** | **String**|  | [optional] 

### Return type

[**BuiltList&lt;UserResponse&gt;**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reactivateUserApiV1AdminUsersUserIdReactivatePost**
> UserResponse reactivateUserApiV1AdminUsersUserIdReactivatePost(userId)

Reactivate User

Admin: reactivate a non-admin user (`is_active=true`) and record an AuditLog row. Idempotent if already active. Refused (400) for the caller's own account or another admin.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.reactivateUserApiV1AdminUsersUserIdReactivatePost(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->reactivateUserApiV1AdminUsersUserIdReactivatePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost**
> WhatsAppDraftResponse rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost(draftId)

Reject Admin Whatsapp Draft

Admin: reject a WhatsApp draft. The live Business row is left untouched (S-053).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String draftId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost(draftId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->rejectAdminWhatsappDraftApiV1AdminWhatsappDraftsDraftIdRejectPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **draftId** | **String**|  | 

### Return type

[**WhatsAppDraftResponse**](WhatsAppDraftResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **suspendUserApiV1AdminUsersUserIdSuspendPost**
> UserResponse suspendUserApiV1AdminUsersUserIdSuspendPost(userId)

Suspend User

Admin: suspend a non-admin user (`is_active=false`) and record an AuditLog row. Idempotent if already inactive. Refused (400) for the caller's own account or another admin.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAdminApi();
final String userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.suspendUserApiV1AdminUsersUserIdSuspendPost(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->suspendUserApiV1AdminUsersUserIdSuspendPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

