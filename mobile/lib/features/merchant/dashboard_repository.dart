import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  Future<DashboardStats> merchantStats(String businessId, {String range = 'all'}) async {
    try {
      final response = await _client.api
          .getDashboardApi()
          .merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId: businessId, range: range);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Raw CSV text for this business's reviews (own business only, backend
  /// ownership check unchanged). The generated client types this endpoint's
  /// response as `JsonObject` since it isn't JSON -- Dio's default json
  /// transformer falls back to the raw response string when the body doesn't
  /// parse as JSON, and `JsonObject` is a pass-through wrapper around
  /// whatever value it's given, so `.value` is that raw CSV string (S-060
  /// Architect spec).
  Future<String> reviewsCsv(String businessId, {String range = 'all'}) async {
    try {
      final response = await _client.api
          .getDashboardApi()
          .merchantDashboardReviewsCsvApiV1DashboardMerchantBusinessIdReviewsCsvGet(businessId: businessId, range: range);
      final value = response.data?.value;
      if (value is! String) {
        throw StateError('Expected CSV text, got ${value.runtimeType}');
      }
      return value;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MerchantInsightsResponse> insights(String businessId) async {
    try {
      final response = await _client.api
          .getAIAnalysisApi()
          .getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet(businessId: businessId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MerchantInsightsResponse> refreshInsights(String businessId) async {
    try {
      final response = await _client.api
          .getAIAnalysisApi()
          .refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost(businessId: businessId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PlatformAnalytics> platformAnalytics() async {
    try {
      final response = await _client.api.getDashboardApi().platformAnalyticsApiV1DashboardAdminPlatformGet();
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Platform-wide time series (new users, businesses approved, new reviews,
  /// new reports) behind the admin home screen's chart row (M-62, S-061).
  /// Day granularity / 90-day window, matching web's own default.
  Future<PlatformAnalyticsSeries> platformAnalyticsSeries() async {
    try {
      final response = await _client.api.getDashboardApi().platformAnalyticsSeriesApiV1DashboardAdminPlatformSeriesGet();
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
