import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final ApiClient _client;

  Future<List<BusinessResponse>> searchBusinesses({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.api.getSearchApi().searchBusinessesApiV1SearchBusinessesGet(
            page: page,
            pageSize: pageSize,
          );
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Public endpoint (no auth required) -- backs the S-023 business detail
  /// screen, which anonymous users can also reach (see ADR-003).
  Future<BusinessResponse> getBySlug(String slug) async {
    try {
      final response = await _client.api.getBusinessesApi().getBusinessApiV1BusinessesSlugGet(slug: slug);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Merchant-only: businesses owned by the current user, used client-side to
  /// hide "Add review" on a merchant's own business (S-023 AC12).
  Future<List<BusinessResponse>> listMine() async {
    try {
      final response = await _client.api.getBusinessesApi().listMyBusinessesApiV1BusinessesMineGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
