import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../storage/token_storage.dart';

/// Mirrors the web frontend's refresh-on-401 contract (frontend/src/lib/api.ts):
/// exactly one refresh-and-retry per request, auth endpoints never trigger a
/// refresh loop, and concurrent 401s share a single in-flight refresh call.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio apiDio,
    required AuthenticationApi authenticationApi,
    required TokenStorage tokenStorage,
  })  : _apiDio = apiDio,
        _authenticationApi = authenticationApi,
        _tokenStorage = tokenStorage;

  static const _noRefreshRetryPrefixes = [
    '/api/v1/auth/login',
    '/api/v1/auth/register',
    '/api/v1/auth/refresh',
    '/api/v1/auth/google',
  ];

  final Dio _apiDio;
  final AuthenticationApi _authenticationApi;
  final TokenStorage _tokenStorage;
  Future<TokenResponse>? _refreshInFlight;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    final isAuthPath = _noRefreshRetryPrefixes.any(path.startsWith);
    final refreshToken = await _tokenStorage.readRefreshToken();

    final canRetry = err.response?.statusCode == 401 && !alreadyRetried && !isAuthPath && refreshToken != null;
    if (!canRetry) {
      handler.next(err);
      return;
    }

    try {
      _refreshInFlight ??= _refreshTokens(refreshToken).whenComplete(() => _refreshInFlight = null);
      final tokens = await _refreshInFlight!;
      await _tokenStorage.save(tokens);

      final retriedOptions = err.requestOptions
        ..extra['retried'] = true
        ..headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      final response = await _apiDio.fetch(retriedOptions);
      handler.resolve(response);
    } catch (_) {
      // Refresh itself failed (expired/invalid refresh token) -- clear tokens
      // and let the original 401 propagate rather than masking it.
      await _tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<TokenResponse> _refreshTokens(String refreshToken) async {
    final response = await _authenticationApi.refreshTokenApiV1AuthRefreshPost(refreshToken: refreshToken);
    return response.data!;
  }
}
