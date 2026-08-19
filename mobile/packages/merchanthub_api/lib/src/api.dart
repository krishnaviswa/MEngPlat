//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'package:merchanthub_api/src/serializers.dart';
import 'package:merchanthub_api/src/auth/api_key_auth.dart';
import 'package:merchanthub_api/src/auth/basic_auth.dart';
import 'package:merchanthub_api/src/auth/bearer_auth.dart';
import 'package:merchanthub_api/src/auth/oauth.dart';
import 'package:merchanthub_api/src/api/ai_analysis_api.dart';
import 'package:merchanthub_api/src/api/admin_api.dart';
import 'package:merchanthub_api/src/api/authentication_api.dart';
import 'package:merchanthub_api/src/api/businesses_api.dart';
import 'package:merchanthub_api/src/api/dashboard_api.dart';
import 'package:merchanthub_api/src/api/default_api.dart';
import 'package:merchanthub_api/src/api/favorites_api.dart';
import 'package:merchanthub_api/src/api/maps_api.dart';
import 'package:merchanthub_api/src/api/merchant_analytics_api.dart';
import 'package:merchanthub_api/src/api/notifications_api.dart';
import 'package:merchanthub_api/src/api/payments_api.dart';
import 'package:merchanthub_api/src/api/photos_api.dart';
import 'package:merchanthub_api/src/api/reviews_api.dart';
import 'package:merchanthub_api/src/api/search_api.dart';
import 'package:merchanthub_api/src/api/support_api.dart';
import 'package:merchanthub_api/src/api/webhooks_api.dart';

class MerchanthubApi {
  static const String basePath = r'http://localhost';

  final Dio dio;
  final Serializers serializers;

  MerchanthubApi({
    Dio? dio,
    Serializers? serializers,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : this.serializers = serializers ?? standardSerializers,
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AIAnalysisApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AIAnalysisApi getAIAnalysisApi() {
    return AIAnalysisApi(dio, serializers);
  }

  /// Get AdminApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminApi getAdminApi() {
    return AdminApi(dio, serializers);
  }

  /// Get AuthenticationApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthenticationApi getAuthenticationApi() {
    return AuthenticationApi(dio, serializers);
  }

  /// Get BusinessesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BusinessesApi getBusinessesApi() {
    return BusinessesApi(dio, serializers);
  }

  /// Get DashboardApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DashboardApi getDashboardApi() {
    return DashboardApi(dio, serializers);
  }

  /// Get DefaultApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DefaultApi getDefaultApi() {
    return DefaultApi(dio, serializers);
  }

  /// Get FavoritesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  FavoritesApi getFavoritesApi() {
    return FavoritesApi(dio, serializers);
  }

  /// Get MapsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MapsApi getMapsApi() {
    return MapsApi(dio, serializers);
  }

  /// Get MerchantAnalyticsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MerchantAnalyticsApi getMerchantAnalyticsApi() {
    return MerchantAnalyticsApi(dio, serializers);
  }

  /// Get NotificationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  NotificationsApi getNotificationsApi() {
    return NotificationsApi(dio, serializers);
  }

  /// Get PaymentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PaymentsApi getPaymentsApi() {
    return PaymentsApi(dio, serializers);
  }

  /// Get PhotosApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PhotosApi getPhotosApi() {
    return PhotosApi(dio, serializers);
  }

  /// Get ReviewsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ReviewsApi getReviewsApi() {
    return ReviewsApi(dio, serializers);
  }

  /// Get SearchApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SearchApi getSearchApi() {
    return SearchApi(dio, serializers);
  }

  /// Get SupportApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SupportApi getSupportApi() {
    return SupportApi(dio, serializers);
  }

  /// Get WebhooksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WebhooksApi getWebhooksApi() {
    return WebhooksApi(dio, serializers);
  }
}
