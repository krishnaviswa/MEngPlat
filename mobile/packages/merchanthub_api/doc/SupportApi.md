# merchanthub_api.api.SupportApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addReportMessageApiV1BusinessReportsReportIdMessagesPost**](SupportApi.md#addreportmessageapiv1businessreportsreportidmessagespost) | **POST** /api/v1/business-reports/{report_id}/messages | Add Report Message
[**createSupportTicketApiV1SupportTicketsPost**](SupportApi.md#createsupportticketapiv1supportticketspost) | **POST** /api/v1/support-tickets | Create Support Ticket
[**listMyBusinessReportsApiV1BusinessReportsMineGet**](SupportApi.md#listmybusinessreportsapiv1businessreportsmineget) | **GET** /api/v1/business-reports/mine | List My Business Reports
[**listMySupportTicketsApiV1SupportTicketsMineGet**](SupportApi.md#listmysupportticketsapiv1supportticketsmineget) | **GET** /api/v1/support-tickets/mine | List My Support Tickets
[**supportContactApiV1SupportContactGet**](SupportApi.md#supportcontactapiv1supportcontactget) | **GET** /api/v1/support/contact | Support Contact


# **addReportMessageApiV1BusinessReportsReportIdMessagesPost**
> BusinessReportMessageResponse addReportMessageApiV1BusinessReportsReportIdMessagesPost(reportId, businessReportMessageCreate)

Add Report Message

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSupportApi();
final String reportId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final BusinessReportMessageCreate businessReportMessageCreate = ; // BusinessReportMessageCreate | 

try {
    final response = api.addReportMessageApiV1BusinessReportsReportIdMessagesPost(reportId, businessReportMessageCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SupportApi->addReportMessageApiV1BusinessReportsReportIdMessagesPost: $e\n');
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

# **createSupportTicketApiV1SupportTicketsPost**
> SupportTicketResponse createSupportTicketApiV1SupportTicketsPost(supportTicketCreate)

Create Support Ticket

Create a support ticket. Auth optional; logged-in users can later list via /mine.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSupportApi();
final SupportTicketCreate supportTicketCreate = ; // SupportTicketCreate | 

try {
    final response = api.createSupportTicketApiV1SupportTicketsPost(supportTicketCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SupportApi->createSupportTicketApiV1SupportTicketsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **supportTicketCreate** | [**SupportTicketCreate**](SupportTicketCreate.md)|  | 

### Return type

[**SupportTicketResponse**](SupportTicketResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyBusinessReportsApiV1BusinessReportsMineGet**
> BuiltList<BusinessReportResponse> listMyBusinessReportsApiV1BusinessReportsMineGet()

List My Business Reports

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSupportApi();

try {
    final response = api.listMyBusinessReportsApiV1BusinessReportsMineGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SupportApi->listMyBusinessReportsApiV1BusinessReportsMineGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;BusinessReportResponse&gt;**](BusinessReportResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMySupportTicketsApiV1SupportTicketsMineGet**
> BuiltList<SupportTicketResponse> listMySupportTicketsApiV1SupportTicketsMineGet()

List My Support Tickets

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSupportApi();

try {
    final response = api.listMySupportTicketsApiV1SupportTicketsMineGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SupportApi->listMySupportTicketsApiV1SupportTicketsMineGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;SupportTicketResponse&gt;**](SupportTicketResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **supportContactApiV1SupportContactGet**
> SupportContactResponse supportContactApiV1SupportContactGet()

Support Contact

Public support email for footer / contact page (S-087).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSupportApi();

try {
    final response = api.supportContactApiV1SupportContactGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SupportApi->supportContactApiV1SupportContactGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SupportContactResponse**](SupportContactResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

