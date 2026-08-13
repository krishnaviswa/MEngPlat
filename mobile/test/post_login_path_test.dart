import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/auth/post_login_path.dart';

void main() {
  test('customer and unknown roles land on Explore', () {
    expect(postLoginPath(UserRole.customer), '/businesses');
    expect(postLoginPath(null), '/businesses');
  });

  test('merchant lands on merchant home', () {
    expect(postLoginPath(UserRole.merchant), '/merchant');
  });

  test('admin lands on admin home', () {
    expect(postLoginPath(UserRole.admin), '/admin');
  });
}
