# merchanthub_api.model.ReviewResponse

## Load the model package
```dart
import 'package:merchanthub_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**businessId** | **String** |  | 
**authorId** | **String** |  | 
**rating** | **int** |  | 
**title** | **String** |  | [optional] 
**body** | **String** |  | 
**status** | [**ReviewStatus**](ReviewStatus.md) |  | 
**likeCount** | **int** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**author** | [**UserResponse**](UserResponse.md) |  | [optional] 
**aiAnalysis** | [**AIAnalysisResponse**](AIAnalysisResponse.md) |  | [optional] 
**reply** | [**ReplyResponse**](ReplyResponse.md) |  | [optional] 
**photoUrls** | **BuiltList&lt;String&gt;** |  | [optional] [default to ListBuilder()]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


