# merchanthub_api.api.SearchApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**searchBusinessesApiV1SearchBusinessesGet**](SearchApi.md#searchbusinessesapiv1searchbusinessesget) | **GET** /api/v1/search/businesses | Search Businesses


# **searchBusinessesApiV1SearchBusinessesGet**
> BuiltList<BusinessResponse> searchBusinessesApiV1SearchBusinessesGet(q, city, category, minRating, sentiment, lat, lng, radiusKm, page, pageSize, sort)

Search Businesses

Search and filter businesses.  **Query params:** q, city, category (slug), min_rating, sentiment, lat, lng, radius_km, page, page_size, sort **Response:** Paginated business list (cached in Redis)

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getSearchApi();
final String q = q_example; // String | Search query
final String city = city_example; // String | 
final String category = category_example; // String | 
final num minRating = 8.14; // num | 
final Sentiment sentiment = ; // Sentiment | 
final num lat = 8.14; // num | 
final num lng = 8.14; // num | 
final num radiusKm = 8.14; // num | 
final int page = 56; // int | 
final int pageSize = 56; // int | 
final String sort = sort_example; // String | rating | name | reviews

try {
    final response = api.searchBusinessesApiV1SearchBusinessesGet(q, city, category, minRating, sentiment, lat, lng, radiusKm, page, pageSize, sort);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SearchApi->searchBusinessesApiV1SearchBusinessesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**| Search query | [optional] 
 **city** | **String**|  | [optional] 
 **category** | **String**|  | [optional] 
 **minRating** | **num**|  | [optional] 
 **sentiment** | [**Sentiment**](.md)|  | [optional] 
 **lat** | **num**|  | [optional] 
 **lng** | **num**|  | [optional] 
 **radiusKm** | **num**|  | [optional] [default to 10.0]
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]
 **sort** | **String**| rating | name | reviews | [optional] [default to 'rating']

### Return type

[**BuiltList&lt;BusinessResponse&gt;**](BusinessResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

