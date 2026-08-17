# merchanthub_api.api.ReviewsApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createReviewApiV1ReviewsPost**](ReviewsApi.md#createreviewapiv1reviewspost) | **POST** /api/v1/reviews | Create Review
[**deleteReviewApiV1ReviewsReviewIdDelete**](ReviewsApi.md#deletereviewapiv1reviewsreviewiddelete) | **DELETE** /api/v1/reviews/{review_id} | Delete Review
[**likeReviewApiV1ReviewsReviewIdLikePost**](ReviewsApi.md#likereviewapiv1reviewsreviewidlikepost) | **POST** /api/v1/reviews/{review_id}/like | Like Review
[**listAdminReviewsApiV1ReviewsAdminAllGet**](ReviewsApi.md#listadminreviewsapiv1reviewsadminallget) | **GET** /api/v1/reviews/admin/all | List Admin Reviews
[**listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet**](ReviewsApi.md#listbusinessreviewsapiv1reviewsbusinessbusinessidget) | **GET** /api/v1/reviews/business/{business_id} | List Business Reviews
[**listReportedReviewsApiV1ReviewsReportedGet**](ReviewsApi.md#listreportedreviewsapiv1reviewsreportedget) | **GET** /api/v1/reviews/reported | List Reported Reviews
[**moderateReviewApiV1ReviewsReviewIdModeratePost**](ReviewsApi.md#moderatereviewapiv1reviewsreviewidmoderatepost) | **POST** /api/v1/reviews/{review_id}/moderate | Moderate Review
[**replyToReviewApiV1ReviewsReviewIdReplyPost**](ReviewsApi.md#replytoreviewapiv1reviewsreviewidreplypost) | **POST** /api/v1/reviews/{review_id}/reply | Reply To Review
[**reportReviewApiV1ReviewsReviewIdReportPost**](ReviewsApi.md#reportreviewapiv1reviewsreviewidreportpost) | **POST** /api/v1/reviews/{review_id}/report | Report Review
[**updateReviewApiV1ReviewsReviewIdPatch**](ReviewsApi.md#updatereviewapiv1reviewsreviewidpatch) | **PATCH** /api/v1/reviews/{review_id} | Update Review


# **createReviewApiV1ReviewsPost**
> ReviewResponse createReviewApiV1ReviewsPost(reviewCreate)

Create Review

Submit a review — triggers automatic AI text analysis.  **Request:** business_id, rating (1-5), title, body (min 10 chars) **Response:** Review with AI analysis attached

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final ReviewCreate reviewCreate = ; // ReviewCreate | 

try {
    final response = api.createReviewApiV1ReviewsPost(reviewCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->createReviewApiV1ReviewsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewCreate** | [**ReviewCreate**](ReviewCreate.md)|  | 

### Return type

[**ReviewResponse**](ReviewResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteReviewApiV1ReviewsReviewIdDelete**
> MessageResponse deleteReviewApiV1ReviewsReviewIdDelete(reviewId)

Delete Review

Delete own review.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteReviewApiV1ReviewsReviewIdDelete(reviewId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->deleteReviewApiV1ReviewsReviewIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **likeReviewApiV1ReviewsReviewIdLikePost**
> MessageResponse likeReviewApiV1ReviewsReviewIdLikePost(reviewId)

Like Review

Like a review (idempotent).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.likeReviewApiV1ReviewsReviewIdLikePost(reviewId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->likeReviewApiV1ReviewsReviewIdLikePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAdminReviewsApiV1ReviewsAdminAllGet**
> BuiltList<ReviewResponse> listAdminReviewsApiV1ReviewsAdminAllGet(businessId, page, pageSize)

List Admin Reviews

Admin: browse reviews across every business and status, optionally scoped to one business (drives both the \"All reviews\" browse view and a business drill-down's review history).  **Query:** business_id (optional scope), page (default 1), page_size (default 20, cap 100) **Response:** Reviews of every status, each carrying its business summary

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.listAdminReviewsApiV1ReviewsAdminAllGet(businessId, page, pageSize);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->listAdminReviewsApiV1ReviewsAdminAllGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]

### Return type

[**BuiltList&lt;ReviewResponse&gt;**](ReviewResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet**
> BuiltList<ReviewResponse> listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet(businessId)

List Business Reviews

List active reviews for a business.  **Path:** business_id **Response:** Reviews with AI analysis, replies, and photo URLs

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BuiltList&lt;ReviewResponse&gt;**](ReviewResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listReportedReviewsApiV1ReviewsReportedGet**
> BuiltList<ReviewResponse> listReportedReviewsApiV1ReviewsReportedGet()

List Reported Reviews

Admin: list reviews flagged for moderation.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();

try {
    final response = api.listReportedReviewsApiV1ReviewsReportedGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->listReportedReviewsApiV1ReviewsReportedGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;ReviewResponse&gt;**](ReviewResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **moderateReviewApiV1ReviewsReviewIdModeratePost**
> MessageResponse moderateReviewApiV1ReviewsReviewIdModeratePost(reviewId, action)

Moderate Review

Admin: hide or restore a review. action=hide|restore|remove

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String action = action_example; // String | 

try {
    final response = api.moderateReviewApiV1ReviewsReviewIdModeratePost(reviewId, action);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->moderateReviewApiV1ReviewsReviewIdModeratePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 
 **action** | **String**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **replyToReviewApiV1ReviewsReviewIdReplyPost**
> ReplyResponse replyToReviewApiV1ReviewsReviewIdReplyPost(reviewId, replyCreate)

Reply To Review

Merchant responds to a review.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ReplyCreate replyCreate = ; // ReplyCreate | 

try {
    final response = api.replyToReviewApiV1ReviewsReviewIdReplyPost(reviewId, replyCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->replyToReviewApiV1ReviewsReviewIdReplyPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 
 **replyCreate** | [**ReplyCreate**](ReplyCreate.md)|  | 

### Return type

[**ReplyResponse**](ReplyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportReviewApiV1ReviewsReviewIdReportPost**
> MessageResponse reportReviewApiV1ReviewsReviewIdReportPost(reviewId, reviewReportCreate)

Report Review

Report inappropriate review.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ReviewReportCreate reviewReportCreate = ; // ReviewReportCreate | 

try {
    final response = api.reportReviewApiV1ReviewsReviewIdReportPost(reviewId, reviewReportCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->reportReviewApiV1ReviewsReviewIdReportPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 
 **reviewReportCreate** | [**ReviewReportCreate**](ReviewReportCreate.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateReviewApiV1ReviewsReviewIdPatch**
> ReviewResponse updateReviewApiV1ReviewsReviewIdPatch(reviewId, reviewUpdate)

Update Review

Edit own review. Re-runs AI analysis if body changes.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getReviewsApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ReviewUpdate reviewUpdate = ; // ReviewUpdate | 

try {
    final response = api.updateReviewApiV1ReviewsReviewIdPatch(reviewId, reviewUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewsApi->updateReviewApiV1ReviewsReviewIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 
 **reviewUpdate** | [**ReviewUpdate**](ReviewUpdate.md)|  | 

### Return type

[**ReviewResponse**](ReviewResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

