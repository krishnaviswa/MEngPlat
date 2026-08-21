/// In-app collect deep link (camera → Flutter) vs the customer web URL.
///
/// HTTPS App Links need a verified Digital Asset Links fingerprint. Until that
/// is live, the merchant-app QR uses [collectAppLink], which Android can open
/// without verification. Share/copy still uses [collectWebLink] so a customer
/// without the app can open the website.
const collectAppScheme = 'merchanthub';
const collectAppHost = 'app';

String collectAppLink(String slugOrId) => '$collectAppScheme://$collectAppHost/collect/$slugOrId';

String collectWebLink(String webBaseUrl, String slugOrId) => '$webBaseUrl/collect/$slugOrId';

/// Maps an incoming platform URI to go_router `/collect/{id}`.
String? collectLocationFromUri(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final i = segments.indexOf('collect');
  if (i >= 0 && i + 1 < segments.length) {
    final id = segments[i + 1];
    if (id.isNotEmpty) return '/collect/$id';
  }
  return null;
}
