import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/core/config/app_config.dart';

void main() {
  test('WEB_BASE_URL compile default is the Next.js origin (http://localhost:3000)', () {
    // String.fromEnvironment is baked at compile time. Tests and local debug
    // builds without --dart-define=WEB_BASE_URL=… must keep this default so
    // merchant collect QR/share links hit the web app, not the API host.
    expect(AppConfig.webBaseUrl, 'http://localhost:3000');
  });
}
