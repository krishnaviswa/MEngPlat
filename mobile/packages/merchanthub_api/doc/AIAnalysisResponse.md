# merchanthub_api.model.AIAnalysisResponse

## Load the model package
```dart
import 'package:merchanthub_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**analysisType** | **String** |  | 
**sentiment** | [**Sentiment**](Sentiment.md) |  | [optional] 
**summary** | **String** |  | [optional] 
**positives** | **BuiltList&lt;String&gt;** |  | [optional] 
**complaints** | **BuiltList&lt;String&gt;** |  | [optional] 
**suggestedResponse** | **String** |  | [optional] 
**imageInsights** | [**JsonObject**](.md) |  | [optional] 
**provider** | **String** |  | 
**degraded** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


