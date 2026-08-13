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
}
