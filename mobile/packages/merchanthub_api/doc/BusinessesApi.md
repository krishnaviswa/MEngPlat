# merchanthub_api.api.BusinessesApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**approveBusinessApiV1BusinessesBusinessIdApprovePost**](BusinessesApi.md#approvebusinessapiv1businessesbusinessidapprovepost) | **POST** /api/v1/businesses/{business_id}/approve | Approve Business
[**createBusinessApiV1BusinessesPost**](BusinessesApi.md#createbusinessapiv1businessespost) | **POST** /api/v1/businesses | Create Business
[**createCategoryApiV1BusinessesCategoriesPost**](BusinessesApi.md#createcategoryapiv1businessescategoriespost) | **POST** /api/v1/businesses/categories | Create Category
[**getBusinessApiV1BusinessesSlugGet**](BusinessesApi.md#getbusinessapiv1businessesslugget) | **GET** /api/v1/businesses/{slug} | Get Business
[**listAllBusinessesAdminApiV1BusinessesAdminAllGet**](BusinessesApi.md#listallbusinessesadminapiv1businessesadminallget) | **GET** /api/v1/businesses/admin/all | List All Businesses Admin
[**listBusinessesApiV1BusinessesGet**](BusinessesApi.md#listbusinessesapiv1businessesget) | **GET** /api/v1/businesses | List Businesses
[**listCategoriesApiV1BusinessesCategoriesAllGet**](BusinessesApi.md#listcategoriesapiv1businessescategoriesallget) | **GET** /api/v1/businesses/categories/all | List Categories
[**listCitiesApiV1BusinessesCitiesGet**](BusinessesApi.md#listcitiesapiv1businessescitiesget) | **GET** /api/v1/businesses/cities | List Cities
[**listExternalReviewsApiV1BusinessesBusinessIdExternalReviewsGet**](BusinessesApi.md#listexternalreviewsapiv1businessesbusinessidexternalreviewsget) | **GET** /api/v1/businesses/{business_id}/external-reviews | List External Reviews
[**listMyBusinessesApiV1BusinessesMineGet**](BusinessesApi.md#listmybusinessesapiv1businessesmineget) | **GET** /api/v1/businesses/mine | List My Businesses
[**publicStatsSummaryApiV1BusinessesStatsSummaryGet**](BusinessesApi.md#publicstatssummaryapiv1businessesstatssummaryget) | **GET** /api/v1/businesses/stats/summary | Public Stats Summary
[**suspendBusinessApiV1BusinessesBusinessIdSuspendPost**](BusinessesApi.md#suspendbusinessapiv1businessesbusinessidsuspendpost) | **POST** /api/v1/businesses/{business_id}/suspend | Suspend Business
[**updateBusinessApiV1BusinessesBusinessIdPatch**](BusinessesApi.md#updatebusinessapiv1businessesbusinessidpatch) | **PATCH** /api/v1/businesses/{business_id} | Update Business


# **approveBusinessApiV1BusinessesBusinessIdApprovePost**
> BusinessResponse approveBusinessApiV1BusinessesBusinessIdApprovePost(businessId)

Approve Business

Admin: approve a pending business. Notifies the merchant in-app and by best-effort email.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.approveBusinessApiV1BusinessesBusinessIdApprovePost(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->approveBusinessApiV1BusinessesBusinessIdApprovePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BusinessResponse**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createBusinessApiV1BusinessesPost**
> BusinessResponse createBusinessApiV1BusinessesPost(businessCreate)

Create Business

Register a new business (merchant only). Status starts as pending.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final BusinessCreate businessCreate = ; // BusinessCreate | 

try {
    final response = api.createBusinessApiV1BusinessesPost(businessCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->createBusinessApiV1BusinessesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessCreate** | [**BusinessCreate**](BusinessCreate.md)|  | 

### Return type

[**BusinessResponse**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createCategoryApiV1BusinessesCategoriesPost**
> CategoryResponse createCategoryApiV1BusinessesCategoriesPost(categoryCreate)

Create Category

Admin: create a new category. 409 if name or slug already exists.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final CategoryCreate categoryCreate = ; // CategoryCreate | 

try {
    final response = api.createCategoryApiV1BusinessesCategoriesPost(categoryCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->createCategoryApiV1BusinessesCategoriesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **categoryCreate** | [**CategoryCreate**](CategoryCreate.md)|  | 

### Return type

[**CategoryResponse**](CategoryResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getBusinessApiV1BusinessesSlugGet**
> BusinessResponse getBusinessApiV1BusinessesSlugGet(slug)

Get Business

Get business profile by slug.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String slug = slug_example; // String | 

try {
    final response = api.getBusinessApiV1BusinessesSlugGet(slug);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->getBusinessApiV1BusinessesSlugGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 

### Return type

[**BusinessResponse**](BusinessResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAllBusinessesAdminApiV1BusinessesAdminAllGet**
> BuiltList<BusinessResponse> listAllBusinessesAdminApiV1BusinessesAdminAllGet(page, pageSize)

List All Businesses Admin

Admin: browse businesses of every status (approved, pending, rejected, suspended), newest-registered first.  **Query:** page (default 1), page_size (default 20, cap 100) **Response:** Businesses of every status — distinct from the public `GET /businesses`, which defaults to approved-only.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.listAllBusinessesAdminApiV1BusinessesAdminAllGet(page, pageSize);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listAllBusinessesAdminApiV1BusinessesAdminAllGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]

### Return type

[**BuiltList&lt;BusinessResponse&gt;**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBusinessesApiV1BusinessesGet**
> BuiltList<BusinessResponse> listBusinessesApiV1BusinessesGet(city, slugs, statusFilter)

List Businesses

List businesses with optional city/slugs filter. Non-approved status filters require admin.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String city = city_example; // String | 
final String slugs = slugs_example; // String | 
final BusinessStatus statusFilter = ; // BusinessStatus | 

try {
    final response = api.listBusinessesApiV1BusinessesGet(city, slugs, statusFilter);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listBusinessesApiV1BusinessesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **city** | **String**|  | [optional] 
 **slugs** | **String**|  | [optional] 
 **statusFilter** | [**BusinessStatus**](.md)|  | [optional] 

### Return type

[**BuiltList&lt;BusinessResponse&gt;**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCategoriesApiV1BusinessesCategoriesAllGet**
> BuiltList<CategoryResponse> listCategoriesApiV1BusinessesCategoriesAllGet()

List Categories

List all business categories.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();

try {
    final response = api.listCategoriesApiV1BusinessesCategoriesAllGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listCategoriesApiV1BusinessesCategoriesAllGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;CategoryResponse&gt;**](CategoryResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCitiesApiV1BusinessesCitiesGet**
> BuiltList<String> listCitiesApiV1BusinessesCitiesGet()

List Cities

Distinct city names for approved businesses (search filter chips).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();

try {
    final response = api.listCitiesApiV1BusinessesCitiesGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listCitiesApiV1BusinessesCitiesGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**BuiltList&lt;String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExternalReviewsApiV1BusinessesBusinessIdExternalReviewsGet**
> BuiltList<ExternalReviewResponse> listExternalReviewsApiV1BusinessesBusinessIdExternalReviewsGet(businessId)

List External Reviews

Public: up to 5 synced third-party (Google) reviews for a business (S-048 AC10, AC11). Two path segments, so this cannot collide with the single-segment `GET /{slug}` above regardless of registration order.  **Response:** `[]` when the business has never linked/synced (AC11) -- callers should not render an \"Also reviewed on Google\" section for an empty list.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listExternalReviewsApiV1BusinessesBusinessIdExternalReviewsGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listExternalReviewsApiV1BusinessesBusinessIdExternalReviewsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BuiltList&lt;ExternalReviewResponse&gt;**](ExternalReviewResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyBusinessesApiV1BusinessesMineGet**
> BuiltList<BusinessResponse> listMyBusinessesApiV1BusinessesMineGet()

List My Businesses

List businesses owned by the current merchant (any status).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();

try {
    final response = api.listMyBusinessesApiV1BusinessesMineGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->listMyBusinessesApiV1BusinessesMineGet: $e\n');
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

# **publicStatsSummaryApiV1BusinessesStatsSummaryGet**
> PublicPlatformStats publicStatsSummaryApiV1BusinessesStatsSummaryGet()

Public Stats Summary

Public platform counts for the home page. Excludes admin-only signals (users, pending, reported).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();

try {
    final response = api.publicStatsSummaryApiV1BusinessesStatsSummaryGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->publicStatsSummaryApiV1BusinessesStatsSummaryGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PublicPlatformStats**](PublicPlatformStats.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **suspendBusinessApiV1BusinessesBusinessIdSuspendPost**
> MessageResponse suspendBusinessApiV1BusinessesBusinessIdSuspendPost(businessId)

Suspend Business

Admin: suspend a business.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.suspendBusinessApiV1BusinessesBusinessIdSuspendPost(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->suspendBusinessApiV1BusinessesBusinessIdSuspendPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateBusinessApiV1BusinessesBusinessIdPatch**
> BusinessResponse updateBusinessApiV1BusinessesBusinessIdPatch(businessId, businessUpdate)

Update Business

Update business details.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getBusinessesApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final BusinessUpdate businessUpdate = ; // BusinessUpdate | 

try {
    final response = api.updateBusinessApiV1BusinessesBusinessIdPatch(businessId, businessUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BusinessesApi->updateBusinessApiV1BusinessesBusinessIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 
 **businessUpdate** | [**BusinessUpdate**](BusinessUpdate.md)|  | 

### Return type

[**BusinessResponse**](BusinessResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

