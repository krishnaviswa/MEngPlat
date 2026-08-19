import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/auth/google_sign_in_client.dart';

void main() {
  test('baked dart-define wins over API client id', () {
    expect(
      resolveGoogleClientId(baked: 'from-define', remote: 'from-api'),
      'from-define',
    );
  });

  test('empty dart-define uses API client id', () {
    expect(
      resolveGoogleClientId(baked: '', remote: 'from-api.apps.googleusercontent.com'),
      'from-api.apps.googleusercontent.com',
    );
  });

  test('both empty stays empty', () {
    expect(resolveGoogleClientId(baked: '', remote: ''), '');
  });
}
