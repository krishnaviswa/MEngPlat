import 'package:dio/dio.dart';

import '../../core/models/business.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final ApiClient _client;

  Future<List<Business>> searchBusinesses({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.apiDio.get<List<dynamic>>(
        '/search/businesses',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return response.data!.map((json) => Business.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
