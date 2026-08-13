import 'config/app_config.dart';

/// Resolve a media path that may be site-relative (`/uploads/...`) against
/// [AppConfig.apiBaseUrl], matching web's `API_URL` prefixing.
String resolveMediaUrl(String url) => url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';
