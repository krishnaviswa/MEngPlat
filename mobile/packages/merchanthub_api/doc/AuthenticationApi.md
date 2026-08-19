# merchanthub_api.api.AuthenticationApi

## Load the API package
```dart
import 'package:merchanthub_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forgotPasswordApiV1AuthForgotPasswordPost**](AuthenticationApi.md#forgotpasswordapiv1authforgotpasswordpost) | **POST** /api/v1/auth/forgot-password | Forgot Password
[**getMeApiV1AuthMeGet**](AuthenticationApi.md#getmeapiv1authmeget) | **GET** /api/v1/auth/me | Get Me
[**googleAuthApiV1AuthGooglePost**](AuthenticationApi.md#googleauthapiv1authgooglepost) | **POST** /api/v1/auth/google | Google Auth
[**loginApiV1AuthLoginPost**](AuthenticationApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login
[**logoutApiV1AuthLogoutPost**](AuthenticationApi.md#logoutapiv1authlogoutpost) | **POST** /api/v1/auth/logout | Logout
[**phoneOtpRequestApiV1AuthPhoneRequestPost**](AuthenticationApi.md#phoneotprequestapiv1authphonerequestpost) | **POST** /api/v1/auth/phone/request | Phone Otp Request
[**phoneOtpVerifyApiV1AuthPhoneVerifyPost**](AuthenticationApi.md#phoneotpverifyapiv1authphoneverifypost) | **POST** /api/v1/auth/phone/verify | Phone Otp Verify
[**refreshTokenApiV1AuthRefreshPost**](AuthenticationApi.md#refreshtokenapiv1authrefreshpost) | **POST** /api/v1/auth/refresh | Refresh Token
[**registerApiV1AuthRegisterPost**](AuthenticationApi.md#registerapiv1authregisterpost) | **POST** /api/v1/auth/register | Register
[**requestAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpRequestPost**](AuthenticationApi.md#requestaadhaarmockotpapiv1authnationalidaadhaarmockotprequestpost) | **POST** /api/v1/auth/national-id/aadhaar/mock-otp/request | Request Aadhaar Mock Otp
[**resetPasswordApiV1AuthResetPasswordPost**](AuthenticationApi.md#resetpasswordapiv1authresetpasswordpost) | **POST** /api/v1/auth/reset-password | Reset Password
[**totpConfirmApiV1AuthMfaTotpConfirmPost**](AuthenticationApi.md#totpconfirmapiv1authmfatotpconfirmpost) | **POST** /api/v1/auth/mfa/totp/confirm | Totp Confirm
[**totpSetupApiV1AuthMfaTotpSetupPost**](AuthenticationApi.md#totpsetupapiv1authmfatotpsetuppost) | **POST** /api/v1/auth/mfa/totp/setup | Totp Setup
[**totpVerifyApiV1AuthMfaTotpVerifyPost**](AuthenticationApi.md#totpverifyapiv1authmfatotpverifypost) | **POST** /api/v1/auth/mfa/totp/verify | Totp Verify
[**updateMeApiV1AuthMePatch**](AuthenticationApi.md#updatemeapiv1authmepatch) | **PATCH** /api/v1/auth/me | Update Me
[**uploadMyAvatarApiV1AuthMeAvatarPost**](AuthenticationApi.md#uploadmyavatarapiv1authmeavatarpost) | **POST** /api/v1/auth/me/avatar | Upload My Avatar
[**verifyAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpVerifyPost**](AuthenticationApi.md#verifyaadhaarmockotpapiv1authnationalidaadhaarmockotpverifypost) | **POST** /api/v1/auth/national-id/aadhaar/mock-otp/verify | Verify Aadhaar Mock Otp


# **forgotPasswordApiV1AuthForgotPasswordPost**
> MessageResponse forgotPasswordApiV1AuthForgotPasswordPost(forgotPasswordRequest)

Forgot Password

Request a password-reset email. Always returns the same generic message, whether or not the address is registered -- the response never confirms account existence (ADR-007).  **Request:** email **Response:** Always 200, generic confirmation copy **Errors:** 422 invalid email shape, 429 rate-limited (5/minute per IP), 503 Redis unreachable (cannot store a hashed token -- fails closed before the account lookup, so the 503 itself does not distinguish known vs unknown addresses)

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final ForgotPasswordRequest forgotPasswordRequest = ; // ForgotPasswordRequest | 

try {
    final response = api.forgotPasswordApiV1AuthForgotPasswordPost(forgotPasswordRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->forgotPasswordApiV1AuthForgotPasswordPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordRequest** | [**ForgotPasswordRequest**](ForgotPasswordRequest.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

Authenticate with email and password.  **Request:** email, password **Response:** Either JWT tokens (should not happen for password accounts without TOTP), or `{ mfa_required, mfa_token }` / `{ mfa_enrollment_required, mfa_token }` for TOTP. **Errors:** 400 account is Google-only (no password set), 401 invalid credentials, 403 inactive, 429 if rate-limited (10/minute per IP) -- bcrypt makes each attempt expensive, so this also caps CPU spent on credential stuffing, not just attempt count. After 5 failed password attempts for the same email, Redis lockout applies for 15 minutes (best-effort; skipped if Redis is unreachable).

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

# **phoneOtpRequestApiV1AuthPhoneRequestPost**
> MessageResponse phoneOtpRequestApiV1AuthPhoneRequestPost(phoneOtpRequest)

Phone Otp Request

Send a 6-digit SMS code. Always the same 200 copy (no user enumeration).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final PhoneOtpRequest phoneOtpRequest = ; // PhoneOtpRequest | 

try {
    final response = api.phoneOtpRequestApiV1AuthPhoneRequestPost(phoneOtpRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->phoneOtpRequestApiV1AuthPhoneRequestPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **phoneOtpRequest** | [**PhoneOtpRequest**](PhoneOtpRequest.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **phoneOtpVerifyApiV1AuthPhoneVerifyPost**
> TokenResponse phoneOtpVerifyApiV1AuthPhoneVerifyPost(phoneOtpVerifyRequest)

Phone Otp Verify

Verify SMS code; register-or-login. Skips TOTP (same as Google).

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final PhoneOtpVerifyRequest phoneOtpVerifyRequest = ; // PhoneOtpVerifyRequest | 

try {
    final response = api.phoneOtpVerifyApiV1AuthPhoneVerifyPost(phoneOtpVerifyRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->phoneOtpVerifyApiV1AuthPhoneVerifyPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **phoneOtpVerifyRequest** | [**PhoneOtpVerifyRequest**](PhoneOtpVerifyRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokenApiV1AuthRefreshPost**
> TokenResponse refreshTokenApiV1AuthRefreshPost(refreshToken)

Refresh Token

Exchange a valid refresh token for a new access + refresh pair. The presented refresh token's jti is blocklisted so it cannot be reused (rotation).  **Request:** refresh_token (query/body depending on client) **Response:** New token pair

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

Register a new user account.  **Request:** email, full_name, password (min 12 chars, at least one letter and one digit), role (customer|merchant|admin blocked for public) **Response:** Created user profile (no tokens — login separately; password login requires TOTP enrollment) **Errors:** 409 if email exists, 422 if password policy fails, 429 if rate-limited (5/minute per IP)

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

# **requestAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpRequestPost**
> MockAadhaarOtpResponse requestAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpRequestPost(mockAadhaarOtpRequest)

Request Aadhaar Mock Otp

Start a MOCK Aadhaar OTP challenge (S-070 / ADR-013). Not a real UIDAI call -- reuses phone_otp.py's Redis hashed-code primitives under a distinct key prefix. The structurally-valid Aadhaar number is held pending in Redis (same TTL as the code) until verify succeeds; it is never persisted here.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MockAadhaarOtpRequest mockAadhaarOtpRequest = ; // MockAadhaarOtpRequest | 

try {
    final response = api.requestAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpRequestPost(mockAadhaarOtpRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->requestAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpRequestPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mockAadhaarOtpRequest** | [**MockAadhaarOtpRequest**](MockAadhaarOtpRequest.md)|  | 

### Return type

[**MockAadhaarOtpResponse**](MockAadhaarOtpResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPasswordApiV1AuthResetPasswordPost**
> MessageResponse resetPasswordApiV1AuthResetPasswordPost(resetPasswordRequest)

Reset Password

Complete a password reset with a token from the reset email.  **Request:** token, new_password (min 12 chars, at least one letter and one digit -- same policy as register) **Response:** Confirmation message. No session tokens are issued -- sign in still requires TOTP (ADR-001). **Errors:** 422 password policy, 400 invalid/expired/already-used token (generic, does not distinguish which), 429 rate-limited (5/minute per IP), 503 Redis unreachable

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final ResetPasswordRequest resetPasswordRequest = ; // ResetPasswordRequest | 

try {
    final response = api.resetPasswordApiV1AuthResetPasswordPost(resetPasswordRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->resetPasswordApiV1AuthResetPasswordPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordRequest** | [**ResetPasswordRequest**](ResetPasswordRequest.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

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

# **uploadMyAvatarApiV1AuthMeAvatarPost**
> UserResponse uploadMyAvatarApiV1AuthMeAvatarPost(file)

Upload My Avatar

Upload/replace the caller's own profile avatar (S-085). Always targets the authenticated caller -- there is no `user_id` param, so this can never set or change another user's avatar.  **Request:** multipart form -- file (image, same content-type/size rules as the business/review photo upload path) **Response:** Updated user profile (`avatar_url` set to the new file's URL) **Errors:** 400 unsupported content-type or file too large, 401 not authenticated

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.uploadMyAvatarApiV1AuthMeAvatarPost(file);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->uploadMyAvatarApiV1AuthMeAvatarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpVerifyPost**
> MessageResponse verifyAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpVerifyPost(mockOtpVerifyRequest)

Verify Aadhaar Mock Otp

Verify the mock Aadhaar OTP code; on success, saves the pending Aadhaar number.

### Example
```dart
import 'package:merchanthub_api/api.dart';

final api = MerchanthubApi().getAuthenticationApi();
final MockOtpVerifyRequest mockOtpVerifyRequest = ; // MockOtpVerifyRequest | 

try {
    final response = api.verifyAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpVerifyPost(mockOtpVerifyRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthenticationApi->verifyAadhaarMockOtpApiV1AuthNationalIdAadhaarMockOtpVerifyPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mockOtpVerifyRequest** | [**MockOtpVerifyRequest**](MockOtpVerifyRequest.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

