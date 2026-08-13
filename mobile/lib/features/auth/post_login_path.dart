import 'package:merchanthub_api/merchanthub_api.dart';

/// Role-aware landing path after login or session restore on `/login` (S-027 / M-09).
///
/// Merchant/admin land on placeholder homes (P4 dashboards stay `future`).
String postLoginPath(UserRole? role) {
  if (role == UserRole.merchant) return '/merchant';
  if (role == UserRole.admin) return '/admin';
  return '/businesses';
}
