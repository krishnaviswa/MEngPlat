# merchanthub_api.api.FavoritesApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createFavoriteApiV1FavoritesPost**](FavoritesApi.md#createfavoriteapiv1favoritespost) | **POST** /api/v1/favorites | Create Favorite
[**deleteFavoriteApiV1FavoritesBusinessIdDelete**](FavoritesApi.md#deletefavoriteapiv1favoritesbusinessiddelete) | **DELETE** /api/v1/favorites/{business_id} | Delete Favorite
[**listFavoritesApiV1FavoritesGet**](FavoritesApi.md#listfavoritesapiv1favoritesget) | **GET** /api/v1/favorites | List Favorites


# **createFavoriteApiV1FavoritesPost**
> FavoriteResponse createFavoriteApiV1FavoritesPost(favoriteCreate)

Create Favorite

Favorite an approved business (idempotent). 404 if missing or not approved.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getFavoritesApi();
final FavoriteCreate favoriteCreate = ; // FavoriteCreate | 

try {
    final response = api.createFavoriteApiV1FavoritesPost(favoriteCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FavoritesApi->createFavoriteApiV1FavoritesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **favoriteCreate** | [**FavoriteCreate**](FavoriteCreate.md)|  | 

### Return type

[**FavoriteResponse**](FavoriteResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteFavoriteApiV1FavoritesBusinessIdDelete**
> deleteFavoriteApiV1FavoritesBusinessIdDelete(businessId)

Delete Favorite

Un-favorite a business (idempotent).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getFavoritesApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deleteFavoriteApiV1FavoritesBusinessIdDelete(businessId);
} catch on DioException (e) {
    print('Exception when calling FavoritesApi->deleteFavoriteApiV1FavoritesBusinessIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFavoritesApiV1FavoritesGet**
> BuiltList<BusinessResponse> listFavoritesApiV1FavoritesGet()

List Favorites

List the current customer's favorited businesses (newest first).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getFavoritesApi();

try {
    final response = api.listFavoritesApiV1FavoritesGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FavoritesApi->listFavoritesApiV1FavoritesGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;BusinessResponse&gt;**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

