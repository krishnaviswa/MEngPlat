import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<UserResponse> login({required String email, required String password}) async {
    try {
      final tokenResponse = await _client.authFreeApi.getAuthenticationApi().loginApiV1AuthLoginPost(
            userLogin: UserLogin((b) => b
              ..email = email
              ..password = password),
          );
      await _client.tokenStorage.save(tokenResponse.data!);
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
