import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Two Dio instances so the refresh call itself can never recurse into the
/// interceptor that triggered it: [authFreeApi] carries no interceptors and
/// is used only for login/register/refresh; [api] carries [AuthInterceptor]
/// and is used for everything else. Both wrap generated `merchanthub_api`
/// clients (see mobile/openapi.json and mobile/packages/merchanthub_api) so
/// request/response models stay in sync with the backend's OpenAPI contract
/// instead of being hand-duplicated.
class ApiClient {
  factory ApiClient({TokenStorage? tokenStorage}) {
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
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

    // Empty `interceptors` so the generated client doesn't attach its own
    // OAuth/Basic/Bearer/ApiKey interceptors on top of ours.
    final authFreeApi = MerchanthubApi(dio: authFreeDio, interceptors: const []);

    apiDio.interceptors.add(
      AuthInterceptor(
        apiDio: apiDio,
        authenticationApi: authFreeApi.getAuthenticationApi(),
        tokenStorage: storage,
      ),
    );

    final api = MerchanthubApi(dio: apiDio, interceptors: const []);

    return ApiClient._(authFreeApi: authFreeApi, api: api, tokenStorage: storage);
  }

  ApiClient._({required this.authFreeApi, required this.api, required this.tokenStorage});

  final MerchanthubApi authFreeApi;
  final MerchanthubApi api;
  final TokenStorage tokenStorage;
}
