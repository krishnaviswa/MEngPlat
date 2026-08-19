import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for MapsApi
void main() {
  final instance = MerchanthubApi().getMapsApi();

  group(MapsApi, () {
    // Maps Config
    //
    // Return public maps configuration for frontend.
    //
    //Future<JsonObject> mapsConfigApiV1MapsConfigGet() async
    test('test mapsConfigApiV1MapsConfigGet', () async {
      // TODO
    });

    // Nearby Businesses
    //
    // Approved businesses within radius of a point (OpenStreetMap / Haversine).  **Request:** lat, lng, radius_km **Response:** Businesses sorted by distance
    //
    //Future<BuiltList<BusinessResponse>> nearbyBusinessesApiV1MapsNearbyPost(NearbyBusinessRequest nearbyBusinessRequest) async
    test('test nearbyBusinessesApiV1MapsNearbyPost', () async {
      // TODO
    });

  });
}
