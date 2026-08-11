import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for SearchApi
void main() {
  final instance = MerchanthubApi().getSearchApi();

  group(SearchApi, () {
    // Search Businesses
    //
    // Search and filter businesses.  **Query params:** q, city, category (slug), min_rating, sentiment, lat, lng, radius_km, page, page_size, sort **Response:** Paginated business list (cached in Redis)
    //
    //Future<BuiltList<BusinessResponse>> searchBusinessesApiV1SearchBusinessesGet({ String q, String city, String category, num minRating, Sentiment sentiment, num lat, num lng, num radiusKm, int page, int pageSize, String sort }) async
    test('test searchBusinessesApiV1SearchBusinessesGet', () async {
      // TODO
    });

  });
}
