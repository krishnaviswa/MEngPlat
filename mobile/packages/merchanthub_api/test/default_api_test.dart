import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for DefaultApi
void main() {
  final instance = MerchanthubApi().getDefaultApi();

  group(DefaultApi, () {
    // Health Check
    //
    //Future<JsonObject> healthCheckHealthGet() async
    test('test healthCheckHealthGet', () async {
      // TODO
    });

    // Root
    //
    //Future<JsonObject> rootGet() async
    test('test rootGet', () async {
      // TODO
    });

  });
}
