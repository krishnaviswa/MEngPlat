# merchanthub_api.api.PhotosApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deletePhotoApiV1PhotosPhotoIdDelete**](PhotosApi.md#deletephotoapiv1photosphotoiddelete) | **DELETE** /api/v1/photos/{photo_id} | Delete Photo
[**listBusinessPhotosApiV1PhotosBusinessBusinessIdGet**](PhotosApi.md#listbusinessphotosapiv1photosbusinessbusinessidget) | **GET** /api/v1/photos/business/{business_id} | List Business Photos
[**uploadPhotoApiV1PhotosUploadPost**](PhotosApi.md#uploadphotoapiv1photosuploadpost) | **POST** /api/v1/photos/upload | Upload Photo


# **deletePhotoApiV1PhotosPhotoIdDelete**
> deletePhotoApiV1PhotosPhotoIdDelete(photoId)

Delete Photo

Delete a photo. Merchants can delete their business photos.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPhotosApi();
final String photoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deletePhotoApiV1PhotosPhotoIdDelete(photoId);
} catch on DioException (e) {
    print('Exception when calling PhotosApi->deletePhotoApiV1PhotosPhotoIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **photoId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBusinessPhotosApiV1PhotosBusinessBusinessIdGet**
> BuiltList<PhotoResponse> listBusinessPhotosApiV1PhotosBusinessBusinessIdGet(businessId)

List Business Photos

List gallery photos for a business.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPhotosApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listBusinessPhotosApiV1PhotosBusinessBusinessIdGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PhotosApi->listBusinessPhotosApiV1PhotosBusinessBusinessIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**BuiltList&lt;PhotoResponse&gt;**](PhotoResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadPhotoApiV1PhotosUploadPost**
> PhotoResponse uploadPhotoApiV1PhotosUploadPost(file, businessId, reviewId, photoType, caption)

Upload Photo

Upload a photo for a business gallery or review. Triggers AI image analysis.  **Request:** multipart form — file, business_id OR review_id, photo_type, caption **Response:** Photo with AI image insights (suggestions only)

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPhotosApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String reviewId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String photoType = photoType_example; // String | 
final String caption = caption_example; // String | 

try {
    final response = api.uploadPhotoApiV1PhotosUploadPost(file, businessId, reviewId, photoType, caption);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PhotosApi->uploadPhotoApiV1PhotosUploadPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 
 **businessId** | **String**|  | [optional] 
 **reviewId** | **String**|  | [optional] 
 **photoType** | **String**|  | [optional] [default to 'gallery']
 **caption** | **String**|  | [optional] 

### Return type

[**PhotoResponse**](PhotoResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

