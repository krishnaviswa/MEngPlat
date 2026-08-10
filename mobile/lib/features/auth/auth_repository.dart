import 'package:dio/dio.dart';

import '../../core/models/token_response.dart';
import '../../core/models/user.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<User> login({required String email, required String password}) async {
    try {
      final tokenResponse = await _client.authFreeDio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final tokens = TokenResponse.fromJson(tokenResponse.data!);
      await _client.tokenStorage.save(tokens);
      return me();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> me() async {
    try {
      final response = await _client.apiDio.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _client.tokenStorage.readRefreshToken();
    try {
      await _client.apiDio.post<void>('/auth/logout', data: {'refresh_token': refreshToken});
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
