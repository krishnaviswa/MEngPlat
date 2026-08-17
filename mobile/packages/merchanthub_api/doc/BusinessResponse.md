# merchanthub_api.model.BusinessResponse

## Load the model package
```dart
import 'package:merchanthub_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**name** | **String** |  | 
**slug** | **String** |  | 
**description** | **String** |  | [optional] 
**address** | **String** |  | 
**city** | **String** |  | 
**state** | **String** |  | [optional] 
**postalCode** | **String** |  | [optional] 
**country** | **String** |  | 
**latitude** | **num** |  | [optional] 
**longitude** | **num** |  | [optional] 
**phone** | **String** |  | [optional] 
**email** | **String** |  | [optional] 
**website** | **String** |  | [optional] 
**logoUrl** | **String** |  | [optional] 
**storefrontUrl** | **String** |  | [optional] 
**businessHours** | [**JsonObject**](.md) |  | [optional] 
**status** | [**BusinessStatus**](BusinessStatus.md) |  | 
**averageRating** | **num** |  | 
**reviewCount** | **int** |  | 
**aiMerchantSummary** | **String** |  | [optional] 
**categories** | [**BuiltList&lt;CategoryResponse&gt;**](CategoryResponse.md) |  | [optional] [default to ListBuilder()]
**isFeatured** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


