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
}
