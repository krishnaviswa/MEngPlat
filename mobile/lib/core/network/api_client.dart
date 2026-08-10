import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Two Dio instances so the refresh call itself can never recurse into the
/// interceptor that triggered it: [authFreeDio] carries no interceptors and
/// is used only for login/register/refresh; [apiDio] carries [AuthInterceptor]
/// and is used for everything else.
class ApiClient {
  factory ApiClient({TokenStorage? tokenStorage}) {
    final baseOptions = BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      // Generous receive timeout: today's dev setup runs the backend locally
      // against a *remote* hosted Postgres (see MOBILE_SETUP_LOG.md), so each
      // request pays several sequential network round trips instead of the
      // near-zero latency it'd see against a co-located DB (Docker Compose
      // locally, or production on Railway's own network).
      receiveTimeout: const Duration(seconds: 30),
    );

    final authFreeDio = Dio(baseOptions);
    final apiDio = Dio(baseOptions);
    final storage = tokenStorage ?? TokenStorage();

    apiDio.interceptors.add(
      AuthInterceptor(apiDio: apiDio, authFreeDio: authFreeDio, tokenStorage: storage),
    );

    return ApiClient._(authFreeDio: authFreeDio, apiDio: apiDio, tokenStorage: storage);
  }

  ApiClient._({required this.authFreeDio, required this.apiDio, required this.tokenStorage});

  final Dio authFreeDio;
  final Dio apiDio;
  final TokenStorage tokenStorage;
}
