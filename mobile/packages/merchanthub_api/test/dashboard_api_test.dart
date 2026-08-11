import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for DashboardApi
void main() {
  final instance = MerchanthubApi().getDashboardApi();

  group(DashboardApi, () {
    // Merchant Dashboard
    //
    // Merchant analytics dashboard data.  **Response:** total reviews, average rating, sentiment breakdown, recent reviews, monthly volume
    //
    //Future<DashboardStats> merchantDashboardApiV1DashboardMerchantBusinessIdGet(String businessId) async
    test('test merchantDashboardApiV1DashboardMerchantBusinessIdGet', () async {
      // TODO
    });

    // Platform Analytics
    //
    // Admin platform-wide analytics.
    //
    //Future<PlatformAnalytics> platformAnalyticsApiV1DashboardAdminPlatformGet() async
    test('test platformAnalyticsApiV1DashboardAdminPlatformGet', () async {
      // TODO
    });

  });
}
