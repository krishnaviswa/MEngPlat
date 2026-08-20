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

  test('GoogleSignInException exposes the message as toString', () {
    final error = GoogleSignInException(
      'Google sign-in is not configured for this app build (SHA-1 / Android OAuth client).',
    );
    expect(error.message, contains('SHA-1'));
    expect(error.toString(), contains('not configured'));
  });

  test('UnconfiguredGoogleSignInClient requestIdToken returns null', () async {
    const client = UnconfiguredGoogleSignInClient();
    expect(client.isConfigured, isFalse);
    expect(await client.requestIdToken(), isNull);
  });
}
