//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:merchanthub_api/src/api_util.dart';
import 'package:merchanthub_api/src/model/business_response.dart';
import 'package:merchanthub_api/src/model/http_validation_error.dart';
import 'package:merchanthub_api/src/model/sentiment.dart';

class SearchApi {

  final Dio _dio;

  final Serializers _serializers;

  const SearchApi(this._dio, this._serializers);

  /// Search Businesses
  /// Search and filter businesses.  **Query params:** q, city, category (slug), min_rating, sentiment, lat, lng, radius_km, page, page_size, sort **Response:** Paginated business list (cached in Redis)
  ///
  /// Parameters:
  /// * [q] - Search query
  /// * [city] 
  /// * [category] 
  /// * [minRating] 
  /// * [sentiment] 
  /// * [lat] 
  /// * [lng] 
  /// * [radiusKm] 
  /// * [page] 
  /// * [pageSize] 
  /// * [sort] - rating | name | reviews
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BuiltList<BusinessResponse>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BuiltList<BusinessResponse>>> searchBusinessesApiV1SearchBusinessesGet({ 
    String? q,
    String? city,
    String? category,
    num? minRating,
    Sentiment? sentiment,
    num? lat,
    num? lng,
    num? radiusKm = 10.0,
    int? page = 1,
    int? pageSize = 20,
    String? sort = 'rating',
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/search/businesses';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'q': encodeQueryParameter(_serializers, q, const FullType(String)),
      r'city': encodeQueryParameter(_serializers, city, const FullType(String)),
      r'category': encodeQueryParameter(_serializers, category, const FullType(String)),
      r'min_rating': encodeQueryParameter(_serializers, minRating, const FullType(num)),
      if (sentiment != null) r'sentiment': encodeQueryParameter(_serializers, sentiment, const FullType(Sentiment)),
      r'lat': encodeQueryParameter(_serializers, lat, const FullType(num)),
      r'lng': encodeQueryParameter(_serializers, lng, const FullType(num)),
      if (radiusKm != null) r'radius_km': encodeQueryParameter(_serializers, radiusKm, const FullType(num)),
      if (page != null) r'page': encodeQueryParameter(_serializers, page, const FullType(int)),
      if (pageSize != null) r'page_size': encodeQueryParameter(_serializers, pageSize, const FullType(int)),
      if (sort != null) r'sort': encodeQueryParameter(_serializers, sort, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BuiltList<BusinessResponse>? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BuiltList, [FullType(BusinessResponse)]),
      ) as BuiltList<BusinessResponse>;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BuiltList<BusinessResponse>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
