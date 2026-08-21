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
  /// Merchant share QR/link encodes this host's `/collect/{slug}` (https only;
  /// phone cameras do not open custom schemes).
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
