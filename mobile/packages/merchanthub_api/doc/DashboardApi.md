# merchanthub_api.api.DashboardApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**merchantDashboardApiV1DashboardMerchantBusinessIdGet**](DashboardApi.md#merchantdashboardapiv1dashboardmerchantbusinessidget) | **GET** /api/v1/dashboard/merchant/{business_id} | Merchant Dashboard
[**platformAnalyticsApiV1DashboardAdminPlatformGet**](DashboardApi.md#platformanalyticsapiv1dashboardadminplatformget) | **GET** /api/v1/dashboard/admin/platform | Platform Analytics


# **merchantDashboardApiV1DashboardMerchantBusinessIdGet**
> DashboardStats merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId)

Merchant Dashboard

Merchant analytics dashboard data.  **Response:** total reviews, average rating, sentiment breakdown, recent reviews, monthly volume

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getDashboardApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardApi->merchantDashboardApiV1DashboardMerchantBusinessIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**DashboardStats**](DashboardStats.md)

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

