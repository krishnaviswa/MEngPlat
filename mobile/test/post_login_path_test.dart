import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/auth/post_login_path.dart';

void main() {
  test('every role lands on marketing Home', () {
    expect(postLoginPath(UserRole.customer), '/home');
    expect(postLoginPath(UserRole.merchant), '/home');
    expect(postLoginPath(UserRole.admin), '/home');
    expect(postLoginPath(null), '/home');
  });

  test('hubPathFor is role-specific', () {
    expect(hubPathFor(UserRole.merchant), '/merchant');
    expect(hubPathFor(UserRole.admin), '/admin');
    expect(hubPathFor(UserRole.customer), '/businesses');
  });

  test('roleLabel is human-readable', () {
    expect(roleLabel(UserRole.merchant), 'Merchant');
    expect(roleLabel(UserRole.admin), 'Admin');
    expect(roleLabel(UserRole.customer), 'Customer');
  });
}
