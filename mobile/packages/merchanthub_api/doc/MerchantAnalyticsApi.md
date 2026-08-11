# merchanthub_api.api.MerchantAnalyticsApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**analyticsSummaryApiV1AnalyticsMerchantBusinessIdSummaryGet**](MerchantAnalyticsApi.md#analyticssummaryapiv1analyticsmerchantbusinessidsummaryget) | **GET** /api/v1/analytics/merchant/{business_id}/summary | Analytics Summary
[**merchantAnalyticsApiV1AnalyticsMerchantBusinessIdGet**](MerchantAnalyticsApi.md#merchantanalyticsapiv1analyticsmerchantbusinessidget) | **GET** /api/v1/analytics/merchant/{business_id} | Merchant Analytics


# **analyticsSummaryApiV1AnalyticsMerchantBusinessIdSummaryGet**
> JsonObject analyticsSummaryApiV1AnalyticsMerchantBusinessIdSummaryGet(businessId)

Analytics Summary

Quick KPI summary for merchant header widgets.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getMerchantAnalyticsApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.analyticsSummaryApiV1AnalyticsMerchantBusinessIdSummaryGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MerchantAnalyticsApi->analyticsSummaryApiV1AnalyticsMerchantBusinessIdSummaryGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **merchantAnalyticsApiV1AnalyticsMerchantBusinessIdGet**
> MerchantInsightsResponse merchantAnalyticsApiV1AnalyticsMerchantBusinessIdGet(businessId)

Merchant Analytics

Merchant analytics endpoint — alias for AI insights with KPI context.  **Path:** business_id **Response:** Full merchant insights package

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getMerchantAnalyticsApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.merchantAnalyticsApiV1AnalyticsMerchantBusinessIdGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MerchantAnalyticsApi->merchantAnalyticsApiV1AnalyticsMerchantBusinessIdGet: $e\n');
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

