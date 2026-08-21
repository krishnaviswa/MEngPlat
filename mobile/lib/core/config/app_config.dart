class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Web OAuth client ID — same value as backend `GOOGLE_CLIENT_ID` and
  /// frontend `NEXT_PUBLIC_GOOGLE_CLIENT_ID`. Empty hides the Google button.
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// Origin of the Next.js web app -- a different deploy from [apiBaseUrl].
  /// Share/copy uses this host's `/collect/{slug}`. The on-screen QR uses
  /// `merchanthub://app/collect/{slug}` so a camera opens Flutter without
  /// App Link verification.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
