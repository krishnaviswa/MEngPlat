# merchanthub_api.model.UserResponse

## Load the model package
```dart
import 'package:merchanthub_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**email** | **String** |  | 
**fullName** | **String** |  | 
**id** | **String** |  | 
**role** | [**UserRole**](UserRole.md) |  | 
**isActive** | **bool** |  | 
**avatarUrl** | **String** |  | [optional] 
**phone** | **String** |  | [optional] 
**addressLine1** | **String** |  | [optional] 
**addressLine2** | **String** |  | [optional] 
**city** | **String** |  | [optional] 
**state** | **String** |  | [optional] 
**postalCode** | **String** |  | [optional] 
**country** | **String** |  | [optional] 
**nationalIdType** | [**NationalIdType**](NationalIdType.md) |  | [optional] 
**nationalIdNumber** | **String** |  | [optional] 
**authProvider** | **String** |  | [optional] [default to 'password']
**totpEnabled** | **bool** |  | [optional] [default to false]
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


