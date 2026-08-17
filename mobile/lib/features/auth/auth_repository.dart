import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  /// Password login is a two-step MFA gate (see S-020): this returns the raw
  /// [LoginResult] rather than a session, since a password account never gets
  /// tokens without also completing [totpVerify] or [totpConfirm].
  Future<LoginResult> login({required String email, required String password}) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().loginApiV1AuthLoginPost(
            userLogin: UserLogin((b) => b
              ..email = email
              ..password = password),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TotpSetupResponse> totpSetup({required String mfaToken}) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().totpSetupApiV1AuthMfaTotpSetupPost(
            mfaTokenRequest: MfaTokenRequest((b) => b..mfaToken = mfaToken),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// First code from a freshly enrolled authenticator; issues session tokens.
  Future<UserResponse> totpConfirm({required String mfaToken, required String code}) {
    return _completeMfa(mfaToken: mfaToken, code: code, confirm: true);
  }

  /// Code from an already-enrolled authenticator; issues session tokens.
  Future<UserResponse> totpVerify({required String mfaToken, required String code}) {
    return _completeMfa(mfaToken: mfaToken, code: code, confirm: false);
  }

  Future<UserResponse> _completeMfa({
    required String mfaToken,
    required String code,
    required bool confirm,
  }) async {
    try {
      final request = MfaTotpCodeRequest((b) => b
        ..mfaToken = mfaToken
        ..code = code);
      final authApi = _client.authFreeApi.getAuthenticationApi();
      final response = confirm
          ? await authApi.totpConfirmApiV1AuthMfaTotpConfirmPost(mfaTotpCodeRequest: request)
          : await authApi.totpVerifyApiV1AuthMfaTotpVerifyPost(mfaTotpCodeRequest: request);
      await _client.tokenStorage.save(response.data!);
      return me();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Creates a password account. Does **not** store tokens — first login must
  /// enroll TOTP (web `RegisterForm` / S-020).
  Future<UserResponse> register({
    required String email,
    required String fullName,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().registerApiV1AuthRegisterPost(
            userRegister: UserRegister((b) => b
              ..email = email
              ..fullName = fullName
              ..password = password
              ..role = role),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Google ID-token exchange. Issues a session immediately (no TOTP).
  Future<UserResponse> loginWithGoogle({required String credential}) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().googleAuthApiV1AuthGooglePost(
            googleAuthRequest: GoogleAuthRequest((b) => b..credential = credential),
          );
      await _client.tokenStorage.save(response.data!);
      return me();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Always returns the same generic confirmation regardless of whether the
  /// email is registered (S-035 / M-65, anti-enumeration by design).
  Future<MessageResponse> forgotPassword({required String email}) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().forgotPasswordApiV1AuthForgotPasswordPost(
            forgotPasswordRequest: ForgotPasswordRequest((b) => b..email = email),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Always returns the same generic confirmation regardless of whether the
  /// number can receive SMS (S-044 / ADR-011 / M-74, anti-enumeration).
  Future<MessageResponse> requestPhoneOtp({required String phone}) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().phoneOtpRequestApiV1AuthPhoneRequestPost(
            phoneOtpRequest: PhoneOtpRequest((b) => b..phone = phone),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Login-or-register in one call; skips TOTP entirely (same trust model as
  /// Google). `fullName`/`role` are only required for a brand-new number.
  Future<UserResponse> verifyPhoneOtp({
    required String phone,
    required String code,
    String? fullName,
    UserRole? role,
  }) async {
    try {
      final response = await _client.authFreeApi.getAuthenticationApi().phoneOtpVerifyApiV1AuthPhoneVerifyPost(
            phoneOtpVerifyRequest: PhoneOtpVerifyRequest((b) => b
              ..phone = phone
              ..code = code
              ..fullName = fullName
              ..role = role),
          );
      await _client.tokenStorage.save(response.data!);
      return me();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserResponse> me() async {
    try {
      final response = await _client.api.getAuthenticationApi().getMeApiV1AuthMeGet();
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserResponse> updateMe(UserProfileUpdate payload) async {
    try {
      final response = await _client.api.getAuthenticationApi().updateMeApiV1AuthMePatch(
            userProfileUpdate: payload,
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _client.tokenStorage.readRefreshToken();
    try {
      await _client.api.getAuthenticationApi().logoutApiV1AuthLogoutPost(
            logoutRequest: LogoutRequest((b) => b..refreshToken = refreshToken),
          );
    } on DioException {
      // Best-effort server-side revocation; local session ends regardless.
    } finally {
      await _client.tokenStorage.clear();
    }
  }

  Future<bool> hasSession() async {
    return await _client.tokenStorage.readAccessToken() != null;
  }
}
