# merchanthub_api.api.AuthenticationApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMeApiV1AuthMeGet**](AuthenticationApi.md#getmeapiv1authmeget) | **GET** /api/v1/auth/me | Get Me
[**googleAuthApiV1AuthGooglePost**](AuthenticationApi.md#googleauthapiv1authgooglepost) | **POST** /api/v1/auth/google | Google Auth
[**loginApiV1AuthLoginPost**](AuthenticationApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login
[**logoutApiV1AuthLogoutPost**](AuthenticationApi.md#logoutapiv1authlogoutpost) | **POST** /api/v1/auth/logout | Logout
[**refreshTokenApiV1AuthRefreshPost**](AuthenticationApi.md#refreshtokenapiv1authrefreshpost) | **POST** /api/v1/auth/refresh | Refresh Token
[**registerApiV1AuthRegisterPost**](AuthenticationApi.md#registerapiv1authregisterpost) | **POST** /api/v1/auth/register | Register
[**totpConfirmApiV1AuthMfaTotpConfirmPost**](AuthenticationApi.md#totpconfirmapiv1authmfatotpconfirmpost) | **POST** /api/v1/auth/mfa/totp/confirm | Totp Confirm
[**totpSetupApiV1AuthMfaTotpSetupPost**](AuthenticationApi.md#totpsetupapiv1authmfatotpsetuppost) | **POST** /api/v1/auth/mfa/totp/setup | Totp Setup
[**totpVerifyApiV1AuthMfaTotpVerifyPost**](AuthenticationApi.md#totpverifyapiv1authmfatotpverifypost) | **POST** /api/v1/auth/mfa/totp/verify | Totp Verify
[**updateMeApiV1AuthMePatch**](AuthenticationApi.md#updatemeapiv1authmepatch) | **PATCH** /api/v1/auth/me | Update Me


# **getMeApiV1AuthMeGet**
> UserResponse getMeApiV1AuthMeGet()

Get Me

Get the currently authenticated user. Requires Bearer token.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();

try {
    final response = api.getMeApiV1AuthMeGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->getMeApiV1AuthMeGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **googleAuthApiV1AuthGooglePost**
> TokenResponse googleAuthApiV1AuthGooglePost(googleAuthRequest)

Google Auth

Sign in (or register) with Google. ID-token flow: the frontend obtains a signed credential from Google Identity Services client-side and sends it here for verification -- no authorization code, no redirect_uri, no client secret on this side.  Google path does **not** require TOTP (Gmail identity is the alternate factor).  **Request:** credential — the ID token JWT from Google's sign-in button **Response:** JWT access_token + refresh_token **Errors:** 401 invalid/expired Google token, 403 email already registered and not Google-verified (link rejected — take over risk), inactive account

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final GoogleAuthRequest googleAuthRequest = ; // GoogleAuthRequest | 

try {
    final response = api.googleAuthApiV1AuthGooglePost(googleAuthRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->googleAuthApiV1AuthGooglePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **googleAuthRequest** | [**GoogleAuthRequest**](GoogleAuthRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginApiV1AuthLoginPost**
> LoginResult loginApiV1AuthLoginPost(userLogin)

Login

Authenticate with email and password.  **Request:** email, password **Response:** Either JWT tokens (should not happen for password accounts without TOTP), or `{ mfa_required, mfa_token }` / `{ mfa_enrollment_required, mfa_token }` for TOTP. **Errors:** 400 account is Google-only (no password set), 401 invalid credentials, 403 inactive

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final UserLogin userLogin = ; // UserLogin | 

try {
    final response = api.loginApiV1AuthLoginPost(userLogin);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->loginApiV1AuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userLogin** | [**UserLogin**](UserLogin.md)|  | 

### Return type

[**LoginResult**](LoginResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logoutApiV1AuthLogoutPost**
> MessageResponse logoutApiV1AuthLogoutPost(logoutRequest)

Logout

Logout: blocklist the caller's access token in Redis (and its refresh token, if supplied), so both stop working immediately instead of lingering until their natural expiry.  **Request:** `Authorization: Bearer <access_token>` header (required); optional JSON body `{\"refresh_token\": \"...\"}` to also revoke a refresh token **Response:** confirmation message **Errors:** 401 if the Authorization header is missing or not a valid access token

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final LogoutRequest logoutRequest = ; // LogoutRequest | 

try {
    final response = api.logoutApiV1AuthLogoutPost(logoutRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->logoutApiV1AuthLogoutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutRequest** | [**LogoutRequest**](LogoutRequest.md)|  | [optional] 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokenApiV1AuthRefreshPost**
> TokenResponse refreshTokenApiV1AuthRefreshPost(refreshToken)

Refresh Token

Exchange a valid refresh token for new access + refresh tokens.  **Request:** refresh_token (query/body depending on client) **Response:** New token pair

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final String refreshToken = refreshToken_example; // String | 

try {
    final response = api.refreshTokenApiV1AuthRefreshPost(refreshToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->refreshTokenApiV1AuthRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshToken** | **String**|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerApiV1AuthRegisterPost**
> UserResponse registerApiV1AuthRegisterPost(userRegister)

Register

Register a new user account.  **Request:** email, full_name, password (min 8 chars), role (customer|merchant|admin blocked for public) **Response:** Created user profile (no tokens — login separately; password login requires TOTP enrollment) **Errors:** 409 if email exists

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final UserRegister userRegister = ; // UserRegister | 

try {
    final response = api.registerApiV1AuthRegisterPost(userRegister);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->registerApiV1AuthRegisterPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userRegister** | [**UserRegister**](UserRegister.md)|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **totpConfirmApiV1AuthMfaTotpConfirmPost**
> TokenResponse totpConfirmApiV1AuthMfaTotpConfirmPost(mfaTotpCodeRequest)

Totp Confirm

Confirm TOTP enrollment with a first code from the authenticator app; issues session tokens.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MfaTotpCodeRequest mfaTotpCodeRequest = ; // MfaTotpCodeRequest | 

try {
    final response = api.totpConfirmApiV1AuthMfaTotpConfirmPost(mfaTotpCodeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->totpConfirmApiV1AuthMfaTotpConfirmPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mfaTotpCodeRequest** | [**MfaTotpCodeRequest**](MfaTotpCodeRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **totpSetupApiV1AuthMfaTotpSetupPost**
> TotpSetupResponse totpSetupApiV1AuthMfaTotpSetupPost(mfaTokenRequest)

Totp Setup

Start TOTP enrollment after password login (mfa_enrollment_required). Returns otpauth URI, manual secret, and QR SVG for the authenticator app.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MfaTokenRequest mfaTokenRequest = ; // MfaTokenRequest | 

try {
    final response = api.totpSetupApiV1AuthMfaTotpSetupPost(mfaTokenRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->totpSetupApiV1AuthMfaTotpSetupPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mfaTokenRequest** | [**MfaTokenRequest**](MfaTokenRequest.md)|  | 

### Return type

[**TotpSetupResponse**](TotpSetupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **totpVerifyApiV1AuthMfaTotpVerifyPost**
> TokenResponse totpVerifyApiV1AuthMfaTotpVerifyPost(mfaTotpCodeRequest)

Totp Verify

Complete password login by verifying the authenticator code; issues session tokens.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MfaTotpCodeRequest mfaTotpCodeRequest = ; // MfaTotpCodeRequest | 

try {
    final response = api.totpVerifyApiV1AuthMfaTotpVerifyPost(mfaTotpCodeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->totpVerifyApiV1AuthMfaTotpVerifyPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mfaTotpCodeRequest** | [**MfaTotpCodeRequest**](MfaTotpCodeRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMeApiV1AuthMePatch**
> UserResponse updateMeApiV1AuthMePatch(userProfileUpdate)

Update Me

Update the caller's own profile (name, avatar, phone, address, national ID). email, role, is_active, and TOTP fields are not on the schema and are silently ignored if sent.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final UserProfileUpdate userProfileUpdate = ; // UserProfileUpdate | 

try {
    final response = api.updateMeApiV1AuthMePatch(userProfileUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->updateMeApiV1AuthMePatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userProfileUpdate** | [**UserProfileUpdate**](UserProfileUpdate.md)|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

