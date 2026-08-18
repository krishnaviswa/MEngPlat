import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// Read-only access to `/payments/*` -- a distinct backend domain from
/// `/dashboard/*`/`/ai/*` (kept out of [DashboardRepository] deliberately,
/// S-062 Architect spec). S-062/M-66: SKU catalog + placement status only.
/// `POST /payments/featured/checkout` is intentionally never called here --
/// mobile checkout is a future, dedicated slice, not this one.
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
}
