import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  Future<DashboardStats> merchantStats(String businessId) async {
    try {
      final response = await _client.api
          .getDashboardApi()
          .merchantDashboardApiV1DashboardMerchantBusinessIdGet(businessId: businessId);
      return response.data!;
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
}
