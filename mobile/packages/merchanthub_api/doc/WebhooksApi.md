# merchanthub_api.api.WebhooksApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**whatsappInboundApiV1WebhooksWhatsappPost**](WebhooksApi.md#whatsappinboundapiv1webhookswhatsapppost) | **POST** /api/v1/webhooks/whatsapp | Whatsapp Inbound
[**whatsappVerifyApiV1WebhooksWhatsappGet**](WebhooksApi.md#whatsappverifyapiv1webhookswhatsappget) | **GET** /api/v1/webhooks/whatsapp | Whatsapp Verify


# **whatsappInboundApiV1WebhooksWhatsappPost**
> WhatsAppWebhookAck whatsappInboundApiV1WebhooksWhatsappPost(xHubSignature256)

Whatsapp Inbound

Inbound WhatsApp messages. Unauthenticated; `X-Hub-Signature-256` HMAC required.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getWebhooksApi();
final String xHubSignature256 = xHubSignature256_example; // String | 

try {
    final response = api.whatsappInboundApiV1WebhooksWhatsappPost(xHubSignature256);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WebhooksApi->whatsappInboundApiV1WebhooksWhatsappPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xHubSignature256** | **String**|  | [optional] 

### Return type

[**WhatsAppWebhookAck**](WhatsAppWebhookAck.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **whatsappVerifyApiV1WebhooksWhatsappGet**
> JsonObject whatsappVerifyApiV1WebhooksWhatsappGet(hubPeriodMode, hubPeriodVerifyToken, hubPeriodChallenge)

Whatsapp Verify

Meta subscription handshake — echo `hub.challenge` when the verify token matches.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getWebhooksApi();
final String hubPeriodMode = hubPeriodMode_example; // String | 
final String hubPeriodVerifyToken = hubPeriodVerifyToken_example; // String | 
final String hubPeriodChallenge = hubPeriodChallenge_example; // String | 

try {
    final response = api.whatsappVerifyApiV1WebhooksWhatsappGet(hubPeriodMode, hubPeriodVerifyToken, hubPeriodChallenge);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WebhooksApi->whatsappVerifyApiV1WebhooksWhatsappGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **hubPeriodMode** | **String**|  | [optional] 
 **hubPeriodVerifyToken** | **String**|  | [optional] 
 **hubPeriodChallenge** | **String**|  | [optional] 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

