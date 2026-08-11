import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class FavoritesRepository {
  FavoritesRepository(this._client);

  final ApiClient _client;

  /// Newest-favorited first (backend's `Favorite.created_at desc` ordering).
  Future<List<BusinessResponse>> listFavorites() async {
    try {
      final response = await _client.api.getFavoritesApi().listFavoritesApiV1FavoritesGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> addFavorite(String businessId) async {
    try {
      await _client.api.getFavoritesApi().createFavoriteApiV1FavoritesPost(
            favoriteCreate: FavoriteCreate((b) => b..businessId = businessId),
          );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeFavorite(String businessId) async {
    try {
      await _client.api.getFavoritesApi().deleteFavoriteApiV1FavoritesBusinessIdDelete(businessId: businessId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
