import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for AIAnalysisApi
void main() {
  final instance = MerchanthubApi().getAIAnalysisApi();

  group(AIAnalysisApi, () {
    // Get Merchant Insights
    //
    // Get aggregated AI insights for a merchant's business.  **Path:** business_id **Response:** Merchant summary, themes, trends, suggested responses **Auth:** Merchant (own business) or Admin  If no summary has been generated yet, this schedules one in the background and returns immediately with merchant_summary=None, rather than blocking the request on a live LLM call as it used to -- a GET should not have unbounded latency (or cost) hiding behind it. Poll again, or use POST .../refresh for a summary you need synchronously.
    //
    //Future<MerchantInsightsResponse> getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet(String businessId) async
    test('test getMerchantInsightsApiV1AiBusinessesBusinessIdInsightsGet', () async {
      // TODO
    });

    // Get Review Analysis
    //
    // Get AI analysis for a specific review.  **Path:** review_id **Response:** Sentiment, summary, positives, complaints, suggested response
    //
    //Future<AIAnalysisResponse> getReviewAnalysisApiV1AiReviewsReviewIdGet(String reviewId) async
    test('test getReviewAnalysisApiV1AiReviewsReviewIdGet', () async {
      // TODO
    });

    // Refresh Insights
    //
    // Manually trigger AI summary refresh for a business. Synchronous, unlike GET .../insights -- this endpoint exists specifically for a caller that wants a fresh summary right now and is willing to wait for it.
    //
    //Future<MerchantInsightsResponse> refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost(String businessId) async
    test('test refreshInsightsApiV1AiBusinessesBusinessIdRefreshPost', () async {
      // TODO
    });

  });
}
