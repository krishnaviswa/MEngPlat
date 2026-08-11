# merchanthub_api.api.MapsApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**geocodeAddressApiV1MapsGeocodeGet**](MapsApi.md#geocodeaddressapiv1mapsgeocodeget) | **GET** /api/v1/maps/geocode | Geocode Address
[**mapsConfigApiV1MapsConfigGet**](MapsApi.md#mapsconfigapiv1mapsconfigget) | **GET** /api/v1/maps/config | Maps Config
[**nearbyBusinessesApiV1MapsNearbyPost**](MapsApi.md#nearbybusinessesapiv1mapsnearbypost) | **POST** /api/v1/maps/nearby | Nearby Businesses


# **geocodeAddressApiV1MapsGeocodeGet**
> GeocodeResponse geocodeAddressApiV1MapsGeocodeGet(address)

Geocode Address

Geocode an address via Nominatim (OpenStreetMap).  **Query:** address **Response:** lat/lng when found; message explains failures

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getMapsApi();
final String address = address_example; // String | 

try {
    final response = api.geocodeAddressApiV1MapsGeocodeGet(address);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MapsApi->geocodeAddressApiV1MapsGeocodeGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **address** | **String**|  | 

### Return type

[**GeocodeResponse**](GeocodeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mapsConfigApiV1MapsConfigGet**
> JsonObject mapsConfigApiV1MapsConfigGet()

Maps Config

Return public maps configuration for frontend.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getMapsApi();

try {
    final response = api.mapsConfigApiV1MapsConfigGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MapsApi->mapsConfigApiV1MapsConfigGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **nearbyBusinessesApiV1MapsNearbyPost**
> BuiltList<BusinessResponse> nearbyBusinessesApiV1MapsNearbyPost(nearbyBusinessRequest)

Nearby Businesses

Approved businesses within radius of a point (OpenStreetMap / Haversine).  **Request:** lat, lng, radius_km **Response:** Businesses sorted by distance

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getMapsApi();
final NearbyBusinessRequest nearbyBusinessRequest = ; // NearbyBusinessRequest | 

try {
    final response = api.nearbyBusinessesApiV1MapsNearbyPost(nearbyBusinessRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MapsApi->nearbyBusinessesApiV1MapsNearbyPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **nearbyBusinessRequest** | [**NearbyBusinessRequest**](NearbyBusinessRequest.md)|  | 

### Return type

[**BuiltList&lt;BusinessResponse&gt;**](BusinessResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

