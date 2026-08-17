# merchanthub_api.api.DashboardApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createWhatsappLinkApiV1DashboardMerchantBusinessIdWhatsappLinkPost**](DashboardApi.md#createwhatsapplinkapiv1dashboardmerchantbusinessidwhatsapplinkpost) | **POST** /api/v1/dashboard/merchant/{business_id}/whatsapp/link | Create Whatsapp Link
[**getGoogleReviewsStatusApiV1DashboardMerchantBusinessIdGoogleReviewsGet**](DashboardApi.md#getgooglereviewsstatusapiv1dashboardmerchantbusinessidgooglereviewsget) | **GET** /api/v1/dashboard/merchant/{business_id}/google-reviews | Get Google Reviews Status
[**linkGooglePlaceApiV1DashboardMerchantBusinessIdGoogleReviewsLinkPost**](DashboardApi.md#linkgoogleplaceapiv1dashboardmerchantbusinessidgooglereviewslinkpost) | **POST** /api/v1/dashboard/merchant/{business_id}/google-reviews/link | Link Google Place
[**listWhatsappDraftsApiV1DashboardMerchantBusinessIdWhatsappDraftsGet**](DashboardApi.md#listwhatsappdraftsapiv1dashboardmerchantbusinessidwhatsappdraftsget) | **GET** /api/v1/dashboard/merchant/{business_id}/whatsapp/drafts | List Whatsapp Drafts
[**merchantBenchmarkApiV1DashboardMerchantBusinessIdBenchmarkGet**](DashboardApi.md#merchantbenchmarkapiv1dashboardmerchantbusinessidbenchmarkget) | **GET** /api/v1/dashboard/merchant/{business_id}/benchmark | Merchant Benchmark
[**merchantDashboardApiV1DashboardMerchantBusinessIdGet**](DashboardApi.md#merchantdashboardapiv1dashboardmerchantbusinessidget) | **GET** /api/v1/dashboard/merchant/{business_id} | Merchant Dashboard
[**merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet**](DashboardApi.md#merchantdashboardreviewscsvapiv1dashboardmerchantbusinessidreviewscsvget) | **GET** /api/v1/dashboard/merchant/{business_id}/reviews.csv | Merchant Dashboard Reviews Csv
[**platformAnalyticsApiV1DashboardAdminPlatformGet**](DashboardApi.md#platformanalyticsapiv1dashboardadminplatformget) | **GET** /api/v1/dashboard/admin/platform | Platform Analytics
[**platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet**](DashboardApi.md#platformanalyticsseriesapiv1dashboardadminplatformseriesget) | **GET** /api/v1/dashboard/admin/platform/series | Platform Analytics Series
[**searchGooglePlacesApiV1DashboardMerchantBusinessIdGoogleReviewsSearchPost**](DashboardApi.md#searchgoogleplacesapiv1dashboardmerchantbusinessidgooglereviewssearchpost) | **POST** /api/v1/dashboard/merchant/{business_id}/google-reviews/search | Search Google Places
[**syncGoogleReviewsApiV1DashboardMerchantBusinessIdGoogleReviewsSyncPost**](DashboardApi.md#syncgooglereviewsapiv1dashboardmerchantbusinessidgooglereviewssyncpost) | **POST** /api/v1/dashboard/merchant/{business_id}/google-reviews/sync | Sync Google Reviews


# **createWhatsappLinkApiV1DashboardMerchantBusinessIdWhatsappLinkPost**
> WhatsAppLinkResponse createWhatsappLinkApiV1DashboardMerchantBusinessIdWhatsappLinkPost(businessId)

Create Whatsapp Link

Generate a short-lived wa.me link that binds inbound WhatsApp to this listing (S-050).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.createWhatsappLinkApiV1DashboardMerchantBusinessIdWhatsappLinkPost(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->createWhatsappLinkApiV1DashboardMerchantBusinessIdWhatsappLinkPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**WhatsAppLinkResponse**](WhatsAppLinkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getGoogleReviewsStatusApiV1DashboardMerchantBusinessIdGoogleReviewsGet**
> GoogleReviewsStatusResponse getGoogleReviewsStatusApiV1DashboardMerchantBusinessIdGoogleReviewsGet(businessId)

Get Google Reviews Status

Link/sync status powering the dashboard card's unlinked/linked/synced states (AC3, AC6, AC7).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getGoogleReviewsStatusApiV1DashboardMerchantBusinessIdGoogleReviewsGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->getGoogleReviewsStatusApiV1DashboardMerchantBusinessIdGoogleReviewsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**GoogleReviewsStatusResponse**](GoogleReviewsStatusResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **linkGooglePlaceApiV1DashboardMerchantBusinessIdGoogleReviewsLinkPost**
> GooglePlaceLinkResponse linkGooglePlaceApiV1DashboardMerchantBusinessIdGoogleReviewsLinkPost(businessId, googlePlaceLinkRequest)

Link Google Place

Link a Google Place ID to this business (AC3). `name`/`address` in the payload are UI-confirmation echoes only, not persisted.  **Response:** `409` if already linked (v1 supports linking once).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final GooglePlaceLinkRequest googlePlaceLinkRequest = ; // GooglePlaceLinkRequest | 

try {
    final response = api.linkGooglePlaceApiV1DashboardMerchantBusinessIdGoogleReviewsLinkPost(businessId, googlePlaceLinkRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->linkGooglePlaceApiV1DashboardMerchantBusinessIdGoogleReviewsLinkPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 
 **googlePlaceLinkRequest** | [**GooglePlaceLinkRequest**](GooglePlaceLinkRequest.md)|  | 

### Return type

[**GooglePlaceLinkResponse**](GooglePlaceLinkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWhatsappDraftsApiV1DashboardMerchantBusinessIdWhatsappDraftsGet**
> BuiltList<WhatsAppDraftResponse> listWhatsappDraftsApiV1DashboardMerchantBusinessIdWhatsappDraftsGet(businessId)

List Whatsapp Drafts

Read-only status of every WhatsApp-derived suggestion for this business, any status, newest first -- apply/discard now happens exclusively via the admin queue (S-053).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listWhatsappDraftsApiV1DashboardMerchantBusinessIdWhatsappDraftsGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->listWhatsappDraftsApiV1DashboardMerchantBusinessIdWhatsappDraftsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BuiltList&lt;WhatsAppDraftResponse&gt;**](WhatsAppDraftResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **merchantBenchmarkApiV1DashboardMerchantBusinessIdBenchmarkGet**
> BenchmarkResponse merchantBenchmarkApiV1DashboardMerchantBusinessIdBenchmarkGet(businessId)

Merchant Benchmark

Category and city rating medians from approved listings. Not an AI judgment.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.merchantBenchmarkApiV1DashboardMerchantBusinessIdBenchmarkGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->merchantBenchmarkApiV1DashboardMerchantBusinessIdBenchmarkGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BenchmarkResponse**](BenchmarkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **merchantDashboardApiV1DashboardMerchantBusinessIdGet**
> DashboardStats merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId, range)

Merchant Dashboard

Merchant analytics dashboard data.  **Query:** `range=30|90|all` (default `all`) filters `review_volume_by_month`, `rating_distribution`, and `reply_rate` by `Review.created_at` (UTC). `total_reviews`, `average_rating`, `sentiment_breakdown`, `recent_reviews` stay all-time.  **Response:** total reviews, average rating, sentiment breakdown, recent reviews, monthly volume, 1-5 rating distribution, reply rate.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String range = range_example; // String | 

try {
    final response = api.merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId, range);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->merchantDashboardApiV1DashboardMerchantBusinessIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 
 **range** | **String**|  | [optional] [default to 'all']

### Return type

[**DashboardStats**](DashboardStats.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet**
> JsonObject merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId, range)

Merchant Dashboard Reviews Csv

Export this business's reviews (own business only) as CSV.  **Query:** `range=30|90|all` (default `all`), same window as the dashboard. **Response:** `text/csv` attachment, one row per in-range review, `created_at` desc.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String range = range_example; // String | 

try {
    final response = api.merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId, range);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 
 **range** | **String**|  | [optional] [default to 'all']

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformAnalyticsApiV1DashboardAdminPlatformGet**
> PlatformAnalytics platformAnalyticsApiV1DashboardAdminPlatformGet()

Platform Analytics

Admin platform-wide analytics.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();

try {
    final response = api.platformAnalyticsApiV1DashboardAdminPlatformGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->platformAnalyticsApiV1DashboardAdminPlatformGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlatformAnalytics**](PlatformAnalytics.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet**
> PlatformAnalyticsSeries platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet(granularity, days)

Platform Analytics Series

Admin time-series: new users, businesses moved pending -> approved (via AuditLog `approve`/`business` rows, not `Business.updated_at`), new reviews, new reports. Each bucket is a stored-timestamp count, zero-filled across the full window -- operational facts, not AI output.  **Query:** `granularity=day|week` (default `day`), `days` 1-365 (default `90`).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String granularity = granularity_example; // String | 
final int days = 56; // int | 

try {
    final response = api.platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet(granularity, days);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **granularity** | **String**|  | [optional] [default to 'day']
 **days** | **int**|  | [optional] [default to 90]

### Return type

[**PlatformAnalyticsSeries**](PlatformAnalyticsSeries.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchGooglePlacesApiV1DashboardMerchantBusinessIdGoogleReviewsSearchPost**
> GooglePlacesSearchResponse searchGooglePlacesApiV1DashboardMerchantBusinessIdGoogleReviewsSearchPost(businessId, googlePlacesSearchRequest)

Search Google Places

Search Google Places for candidates to link (AC1-5). Lat/lng bias comes from the loaded `Business`, not the client.  **Response:** `candidates` (empty list is a valid 200 -- AC4); `502` on provider timeout/error, existing linked state untouched (AC5).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final GooglePlacesSearchRequest googlePlacesSearchRequest = ; // GooglePlacesSearchRequest | 

try {
    final response = api.searchGooglePlacesApiV1DashboardMerchantBusinessIdGoogleReviewsSearchPost(businessId, googlePlacesSearchRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->searchGooglePlacesApiV1DashboardMerchantBusinessIdGoogleReviewsSearchPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 
 **googlePlacesSearchRequest** | [**GooglePlacesSearchRequest**](GooglePlacesSearchRequest.md)|  | 

### Return type

[**GooglePlacesSearchResponse**](GooglePlacesSearchResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **syncGoogleReviewsApiV1DashboardMerchantBusinessIdGoogleReviewsSyncPost**
> GoogleReviewsSyncResponse syncGoogleReviewsApiV1DashboardMerchantBusinessIdGoogleReviewsSyncPost(businessId)

Sync Google Reviews

Fetch up to 5 reviews from Google and upsert them (AC7, AC8). Debounced via a Redis lock (AC9) -- a concurrent/duplicate click returns the current state with `debounced: true` instead of erroring or duplicating.  **Response:** `400` if unlinked; `502` on provider failure, existing `ExternalReview` rows left untouched.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.syncGoogleReviewsApiV1DashboardMerchantBusinessIdGoogleReviewsSyncPost(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->syncGoogleReviewsApiV1DashboardMerchantBusinessIdGoogleReviewsSyncPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**GoogleReviewsSyncResponse**](GoogleReviewsSyncResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

