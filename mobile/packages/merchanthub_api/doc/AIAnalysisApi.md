# merchanthub_api.api.AIAnalysisApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet**](AIAnalysisApi.md#getmerchantinsightsapiv1aibusinessesbusinessidinsightsget) | **GET** /api/v1/ai/businesses/{business_id}/insights | Get Merchant Insights
[**getReviewAnalysisApiV1AiReviewsReviewIdGet**](AIAnalysisApi.md#getreviewanalysisapiv1aireviewsreviewidget) | **GET** /api/v1/ai/reviews/{review_id} | Get Review Analysis
[**refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost**](AIAnalysisApi.md#refreshinsightsapiv1aibusinessesbusinessidrefreshpost) | **POST** /api/v1/ai/businesses/{business_id}/refresh | Refresh Insights


# **getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet**
> MerchantInsightsResponse getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet(businessId)

Get Merchant Insights

Get aggregated AI insights for a merchant's business.  **Path:** business_id **Response:** Merchant summary, themes, trends, suggested responses **Auth:** Merchant (own business) or Admin  If no summary has been generated yet, this schedules one in the background and returns immediately with merchant_summary=None, rather than blocking the request on a live LLM call as it used to -- a GET should not have unbounded latency (or cost) hiding behind it. Poll again, or use POST .../refresh for a summary you need synchronously.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAIAnalysisApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AIAnalysisApi->getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**MerchantInsightsResponse**](MerchantInsightsResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getReviewAnalysisApiV1AiReviewsReviewIdGet**
> AIAnalysisResponse getReviewAnalysisApiV1AiReviewsReviewIdGet(reviewId)

Get Review Analysis

Get AI analysis for a specific review.  **Path:** review_id **Response:** Sentiment, summary, positives, complaints, suggested response

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAIAnalysisApi();
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getReviewAnalysisApiV1AiReviewsReviewIdGet(reviewId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AIAnalysisApi->getReviewAnalysisApiV1AiReviewsReviewIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reviewId** | **String**|  | 

### Return type

[**AIAnalysisResponse**](AIAnalysisResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost**
> MerchantInsightsResponse refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost(businessId)

Refresh Insights

Manually trigger AI summary refresh for a business. Synchronous, unlike GET .../insights -- this endpoint exists specifically for a caller that wants a fresh summary right now and is willing to wait for it.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAIAnalysisApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AIAnalysisApi->refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**MerchantInsightsResponse**](MerchantInsightsResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

