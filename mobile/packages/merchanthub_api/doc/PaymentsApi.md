# merchanthub_api.api.PaymentsApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost**](PaymentsApi.md#adminapprovepaymentapiv1paymentsadminpaymentspaymentidapprovepost) | **POST** /api/v1/payments/admin/payments/{payment_id}/approve | Admin Approve Payment
[**adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost**](PaymentsApi.md#admindisableplacementapiv1paymentsadminplacementsplacementiddisablepost) | **POST** /api/v1/payments/admin/placements/{placement_id}/disable | Admin Disable Placement
[**adminListPaymentsApiV1PaymentsAdminPaymentsGet**](PaymentsApi.md#adminlistpaymentsapiv1paymentsadminpaymentsget) | **GET** /api/v1/payments/admin/payments | Admin List Payments
[**adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost**](PaymentsApi.md#adminrefundpaymentapiv1paymentsadminpaymentspaymentidrefundpost) | **POST** /api/v1/payments/admin/payments/{payment_id}/refund | Admin Refund Payment
[**adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost**](PaymentsApi.md#adminrejectpaymentapiv1paymentsadminpaymentspaymentidrejectpost) | **POST** /api/v1/payments/admin/payments/{payment_id}/reject | Admin Reject Payment
[**featuredCheckoutApiV1PaymentsFeaturedCheckoutPost**](PaymentsApi.md#featuredcheckoutapiv1paymentsfeaturedcheckoutpost) | **POST** /api/v1/payments/featured/checkout | Featured Checkout
[**featuredSkusApiV1PaymentsFeaturedSkusGet**](PaymentsApi.md#featuredskusapiv1paymentsfeaturedskusget) | **GET** /api/v1/payments/featured/skus | Featured Skus
[**getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet**](PaymentsApi.md#getplacementapiv1paymentsbusinessesbusinessidplacementget) | **GET** /api/v1/payments/businesses/{business_id}/placement | Get Placement
[**mockCompleteApiV1PaymentsMockCompletePost**](PaymentsApi.md#mockcompleteapiv1paymentsmockcompletepost) | **POST** /api/v1/payments/mock/complete | Mock Complete
[**razorpayWebhookApiV1PaymentsWebhooksRazorpayPost**](PaymentsApi.md#razorpaywebhookapiv1paymentswebhooksrazorpaypost) | **POST** /api/v1/payments/webhooks/razorpay | Razorpay Webhook


# **adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost**
> PaymentApproveResponse adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost(paymentId)

Admin Approve Payment

Admin: after capture, create the featured placement window.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost(paymentId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentId** | **String**|  | 

### Return type

[**PaymentApproveResponse**](PaymentApproveResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost**
> PlacementDisableResponse adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost(placementId)

Admin Disable Placement

Admin: drop featured rank without refund.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String placementId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost(placementId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placementId** | **String**|  | 

### Return type

[**PlacementDisableResponse**](PlacementDisableResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListPaymentsApiV1PaymentsAdminPaymentsGet**
> BuiltList<AdminPaymentRow> adminListPaymentsApiV1PaymentsAdminPaymentsGet(page, pageSize)

Admin List Payments

Admin: all featured payments, newest first, with per-merchant counts.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListPaymentsApiV1PaymentsAdminPaymentsGet(page, pageSize);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->adminListPaymentsApiV1PaymentsAdminPaymentsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 20]

### Return type

[**BuiltList&lt;AdminPaymentRow&gt;**](AdminPaymentRow.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost**
> PaymentRefundResponse adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost(paymentId)

Admin Refund Payment

Admin: refund provider charge and disable linked placement.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost(paymentId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentId** | **String**|  | 

### Return type

[**PaymentRefundResponse**](PaymentRefundResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost**
> PaymentRejectResponse adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost(paymentId)

Admin Reject Payment

Admin: refuse the boost. Does not refund.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost(paymentId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentId** | **String**|  | 

### Return type

[**PaymentRejectResponse**](PaymentRejectResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **featuredCheckoutApiV1PaymentsFeaturedCheckoutPost**
> FeaturedCheckoutResponse featuredCheckoutApiV1PaymentsFeaturedCheckoutPost(featuredCheckoutRequest)

Featured Checkout

Start featured checkout for an owned approved listing. Auth: merchant. sku_code required.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final FeaturedCheckoutRequest featuredCheckoutRequest = ; // FeaturedCheckoutRequest | 

try {
    final response = api.featuredCheckoutApiV1PaymentsFeaturedCheckoutPost(featuredCheckoutRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->featuredCheckoutApiV1PaymentsFeaturedCheckoutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **featuredCheckoutRequest** | [**FeaturedCheckoutRequest**](FeaturedCheckoutRequest.md)|  | 

### Return type

[**FeaturedCheckoutResponse**](FeaturedCheckoutResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **featuredSkusApiV1PaymentsFeaturedSkusGet**
> BuiltList<FeaturedSku> featuredSkusApiV1PaymentsFeaturedSkusGet()

Featured Skus

Catalog of featured listing SKUs. Auth: merchant or admin.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();

try {
    final response = api.featuredSkusApiV1PaymentsFeaturedSkusGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->featuredSkusApiV1PaymentsFeaturedSkusGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;FeaturedSku&gt;**](FeaturedSku.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet**
> PlacementResponse getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(businessId)

Get Placement

Active/expiry for a listing. Fee split is admin-only. Catalog always included.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String businessId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(businessId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **businessId** | **String**|  | 

### Return type

[**PlacementResponse**](PlacementResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mockCompleteApiV1PaymentsMockCompletePost**
> WebhookAck mockCompleteApiV1PaymentsMockCompletePost(mockCompleteRequest)

Mock Complete

DEBUG-only: admin completes a mock order (ledger only). 404 when DEBUG is false.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final MockCompleteRequest mockCompleteRequest = ; // MockCompleteRequest | 

try {
    final response = api.mockCompleteApiV1PaymentsMockCompletePost(mockCompleteRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->mockCompleteApiV1PaymentsMockCompletePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mockCompleteRequest** | [**MockCompleteRequest**](MockCompleteRequest.md)|  | 

### Return type

[**WebhookAck**](WebhookAck.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **razorpayWebhookApiV1PaymentsWebhooksRazorpayPost**
> WebhookAck razorpayWebhookApiV1PaymentsWebhooksRazorpayPost(xRazorpaySignature)

Razorpay Webhook

Razorpay (or signed mock) webhook. Unauthenticated; HMAC required.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getPaymentsApi();
final String xRazorpaySignature = xRazorpaySignature_example; // String | 

try {
    final response = api.razorpayWebhookApiV1PaymentsWebhooksRazorpayPost(xRazorpaySignature);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->razorpayWebhookApiV1PaymentsWebhooksRazorpayPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xRazorpaySignature** | **String**|  | [optional] 

### Return type

[**WebhookAck**](WebhookAck.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

