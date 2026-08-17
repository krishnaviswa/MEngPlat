# merchanthub_api.model.PlacementResponse

## Load the model package
```dart
import 'package:merchanthub_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**businessId** | **String** |  | 
**active** | **bool** |  | 
**placement** | [**PlacementWindow**](PlacementWindow.md) |  | [optional] 
**sku** | [**FeaturedSku**](FeaturedSku.md) |  | 
**skus** | [**BuiltList&lt;FeaturedSku&gt;**](FeaturedSku.md) |  | [optional] [default to ListBuilder()]
**awaitingApproval** | **bool** |  | [optional] [default to false]
**payment** | [**PaymentLedger**](PaymentLedger.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


