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
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 30),
      // Shop/Grow fires several Railway round-trips at once; 30s still
      // surfaced as "That took too long" on merchant phones.
      receiveTimeout: const Duration(seconds: 60),
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
