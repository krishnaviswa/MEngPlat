import 'package:merchanthub_api/merchanthub_api.dart';

/// Everyone lands on marketing Home after login. Hub is a tab/button, not the
/// post-login dump for merchants and admins.
String postLoginPath(UserRole? role) {
  switch (role) {
    case UserRole.merchant:
    case UserRole.admin:
    case UserRole.customer:
    case null:
      return '/home';
    default:
      return '/home';
  }
}

String hubPathFor(UserRole? role) {
  if (role == UserRole.merchant) return '/merchant';
  if (role == UserRole.admin) return '/admin';
  return '/businesses';
}

String roleLabel(UserRole? role) => switch (role) {
      UserRole.merchant => 'Merchant',
      UserRole.admin => 'Admin',
      UserRole.customer => 'Customer',
      null => 'Guest',
      _ => 'Guest',
    };
