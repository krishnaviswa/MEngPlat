import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for WebhooksApi
void main() {
  final instance = MerchanthubApi().getWebhooksApi();

  group(WebhooksApi, () {
    // Whatsapp Inbound
    //
    // Inbound WhatsApp messages. Unauthenticated; `X-Hub-Signature-256` HMAC required.
    //
    //Future<WhatsAppWebhookAck> whatsappInboundApiV1WebhooksWhatsappPost({ String xHubSignature256 }) async
    test('test whatsappInboundApiV1WebhooksWhatsappPost', () async {
      // TODO
    });

    // Whatsapp Verify
    //
    // Meta subscription handshake — echo `hub.challenge` when the verify token matches.
    //
    //Future<JsonObject> whatsappVerifyApiV1WebhooksWhatsappGet({ String hubPeriodMode, String hubPeriodVerifyToken, String hubPeriodChallenge }) async
    test('test whatsappVerifyApiV1WebhooksWhatsappGet', () async {
      // TODO
    });

  });
}
