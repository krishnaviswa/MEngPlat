# TR-S-066: Mobile remaining web capability parity

## Summary
Pass — Flutter `analyze` clean. Full `flutter test` was 245 passing / 4 failing; the four failures were fixed (restored admin categories button, stubbed public Google fetch on shell, unique suggestion finder, SKU checkout assertions) and those files re-ran **43/43**.

## AC coverage matrix
| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Benchmark card + disclaimer | A | `merchant_dashboard_screen_test.dart` M-69 | Pass |
| 2 | Draft with AI fills, does not post | A | `review_card_test.dart` M-70 | Pass |
| 3 | Common Themes suggestion line | A | `merchant_dashboard_screen_test.dart` M-78 | Pass |
| 4 | SKU `checkoutFeatured` mock pending order | A | `merchant_dashboard_screen_test.dart` M-66 | Pass |
| 5 | Google link CTA + public samples / hide empty | A | dashboard M-80 + `business_detail_screen_test.dart` | Pass |
| 6 | WhatsApp disclaimer + admin approve removes row | A | dashboard M-79 + `admin_whatsapp_queue_screen_test.dart` | Pass |
| 7 | Suggestion labeling | A | insights / WhatsApp / draft disclaimer keys | Pass |
| 8 | Honest tracker leftovers | Inspection | README §12 M-65/M-71 `partial`, M-67 `n/a`, M-47 `future` | Pass |

## Recommendation
Ship. PM can set S-066 **Accepted**. Remaining non-capability items: app-links (M-65/M-71), FCM (M-47), native Razorpay SDK.
