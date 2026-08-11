import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for FavoritesApi
void main() {
  final instance = MerchanthubApi().getFavoritesApi();

  group(FavoritesApi, () {
    // Create Favorite
    //
    // Favorite an approved business (idempotent). 404 if missing or not approved.
    //
    //Future<FavoriteResponse> createFavoriteApiV1FavoritesPost(FavoriteCreate favoriteCreate) async
    test('test createFavoriteApiV1FavoritesPost', () async {
      // TODO
    });

    // Delete Favorite
    //
    // Un-favorite a business (idempotent).
    //
    //Future deleteFavoriteApiV1FavoritesBusinessIdDelete(String businessId) async
    test('test deleteFavoriteApiV1FavoritesBusinessIdDelete', () async {
      // TODO
    });

    // List Favorites
    //
    // List the current customer's favorited businesses (newest first).
    //
    //Future<BuiltList<BusinessResponse>> listFavoritesApiV1FavoritesGet() async
    test('test listFavoritesApiV1FavoritesGet', () async {
      // TODO
    });

  });
}
