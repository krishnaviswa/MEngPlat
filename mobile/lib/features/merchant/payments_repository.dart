import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// Access to `/payments/*` -- a distinct backend domain from
/// `/dashboard/*`/`/ai/*` (kept out of [DashboardRepository] deliberately).
class PaymentsRepository {
  PaymentsRepository(this._client);

  final ApiClient _client;

  Future<List<FeaturedSku>> featuredSkus() async {
    try {
      final response = await _client.api.getPaymentsApi().featuredSkusApiV1PaymentsFeaturedSkusGet();
      return response.data?.toList() ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PlacementResponse> placement(String businessId) async {
    try {
      final response = await _client.api
          .getPaymentsApi()
          .getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(businessId: businessId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<FeaturedCheckoutResponse> checkoutFeatured({
    required String businessId,
    required String skuCode,
  }) async {
    try {
      final response = await _client.api.getPaymentsApi().featuredCheckoutApiV1PaymentsFeaturedCheckoutPost(
        featuredCheckoutRequest: FeaturedCheckoutRequest(
          (b) => b
            ..businessId = businessId
            ..skuCode = skuCode,
        ),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
