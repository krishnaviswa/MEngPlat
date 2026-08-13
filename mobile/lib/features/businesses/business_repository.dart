import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'maps_config.dart';
import 'search_query.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final ApiClient _client;

  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async {
    try {
      final response = await _client.api.getSearchApi().searchBusinessesApiV1SearchBusinessesGet(
            q: query.q,
            city: query.city,
            category: query.category,
            minRating: query.minRating,
            lat: query.lat,
            lng: query.lng,
            radiusKm: query.hasLocation ? query.radiusKm : null,
            page: page,
            pageSize: pageSize,
            sort: query.sort,
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

  Future<List<String>> listCities() async {
    try {
      final response = await _client.api.getBusinessesApi().listCitiesApiV1BusinessesCitiesGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<CategoryResponse>> listCategories() async {
    try {
      final response = await _client.api.getBusinessesApi().listCategoriesApiV1BusinessesCategoriesAllGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<PhotoResponse>> listPhotos(String businessId) async {
    try {
      final response = await _client.api.getPhotosApi().listBusinessPhotosApiV1PhotosBusinessBusinessIdGet(
            businessId: businessId,
          );
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MapsConfig> mapsConfig() async {
    try {
      final response = await _client.api.getMapsApi().mapsConfigApiV1MapsConfigGet();
      return mapsConfigFromJson(response.data);
    } on DioException {
      return MapsConfig.fallback;
    }
  }

  Future<BusinessResponse> createBusiness(BusinessCreate payload) async {
    try {
      final response = await _client.api.getBusinessesApi().createBusinessApiV1BusinessesPost(businessCreate: payload);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BusinessResponse> updateBusiness({required String businessId, required BusinessUpdate payload}) async {
    try {
      final response = await _client.api.getBusinessesApi().updateBusinessApiV1BusinessesBusinessIdPatch(
            businessId: businessId,
            businessUpdate: payload,
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BusinessResponse>> listByStatus(BusinessStatus status) async {
    try {
      final response = await _client.api.getBusinessesApi().listBusinessesApiV1BusinessesGet(statusFilter: status);
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BusinessResponse> approveBusiness(String businessId) async {
    try {
      final response =
          await _client.api.getBusinessesApi().approveBusinessApiV1BusinessesBusinessIdApprovePost(businessId: businessId);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> suspendBusiness(String businessId) async {
    try {
      await _client.api.getBusinessesApi().suspendBusinessApiV1BusinessesBusinessIdSuspendPost(businessId: businessId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /businesses/admin/all` is not on the generated client; same Dio + serializers (S-031).
  Future<List<BusinessResponse>> listAdminAll({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.api.dio.get<Object>(
        '/api/v1/businesses/admin/all',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final decoded = standardSerializers.deserialize(
        response.data,
        specifiedType: const FullType(BuiltList, [FullType(BusinessResponse)]),
      ) as BuiltList<BusinessResponse>;
      return decoded.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
