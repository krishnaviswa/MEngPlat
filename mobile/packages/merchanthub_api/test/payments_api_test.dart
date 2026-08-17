import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for PaymentsApi
void main() {
  final instance = MerchanthubApi().getPaymentsApi();

  group(PaymentsApi, () {
    // Admin Approve Payment
    //
    // Admin: after capture, create the featured placement window.
    //
    //Future<PaymentApproveResponse> adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost(String paymentId) async
    test('test adminApprovePaymentApiV1PaymentsAdminPaymentsPaymentIdApprovePost', () async {
      // TODO
    });

    // Admin Disable Placement
    //
    // Admin: drop featured rank without refund.
    //
    //Future<PlacementDisableResponse> adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost(String placementId) async
    test('test adminDisablePlacementApiV1PaymentsAdminPlacementsPlacementIdDisablePost', () async {
      // TODO
    });

    // Admin List Payments
    //
    // Admin: all featured payments, newest first, with per-merchant counts.
    //
    //Future<BuiltList<AdminPaymentRow>> adminListPaymentsApiV1PaymentsAdminPaymentsGet({ int page, int pageSize }) async
    test('test adminListPaymentsApiV1PaymentsAdminPaymentsGet', () async {
      // TODO
    });

    // Admin Refund Payment
    //
    // Admin: refund provider charge and disable linked placement.
    //
    //Future<PaymentRefundResponse> adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost(String paymentId) async
    test('test adminRefundPaymentApiV1PaymentsAdminPaymentsPaymentIdRefundPost', () async {
      // TODO
    });

    // Admin Reject Payment
    //
    // Admin: refuse the boost. Does not refund.
    //
    //Future<PaymentRejectResponse> adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost(String paymentId) async
    test('test adminRejectPaymentApiV1PaymentsAdminPaymentsPaymentIdRejectPost', () async {
      // TODO
    });

    // Featured Checkout
    //
    // Start featured checkout for an owned approved listing. Auth: merchant. sku_code required.
    //
    //Future<FeaturedCheckoutResponse> featuredCheckoutApiV1PaymentsFeaturedCheckoutPost(FeaturedCheckoutRequest featuredCheckoutRequest) async
    test('test featuredCheckoutApiV1PaymentsFeaturedCheckoutPost', () async {
      // TODO
    });

    // Featured Skus
    //
    // Catalog of featured listing SKUs. Auth: merchant or admin.
    //
    //Future<BuiltList<FeaturedSku>> featuredSkusApiV1PaymentsFeaturedSkusGet() async
    test('test featuredSkusApiV1PaymentsFeaturedSkusGet', () async {
      // TODO
    });

    // Get Placement
    //
    // Active/expiry for a listing. Fee split is admin-only. Catalog always included.
    //
    //Future<PlacementResponse> getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(String businessId) async
    test('test getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet', () async {
      // TODO
    });

    // Mock Complete
    //
    // DEBUG-only: admin completes a mock order (ledger only). 404 when DEBUG is false.
    //
    //Future<WebhookAck> mockCompleteApiV1PaymentsMockCompletePost(MockCompleteRequest mockCompleteRequest) async
    test('test mockCompleteApiV1PaymentsMockCompletePost', () async {
      // TODO
    });

    // Razorpay Webhook
    //
    // Razorpay (or signed mock) webhook. Unauthenticated; HMAC required.
    //
    //Future<WebhookAck> razorpayWebhookApiV1PaymentsWebhooksRazorpayPost({ String xRazorpaySignature }) async
    test('test razorpayWebhookApiV1PaymentsWebhooksRazorpayPost', () async {
      // TODO
    });

  });
}
