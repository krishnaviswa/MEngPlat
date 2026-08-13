import 'package:built_value/json_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/businesses/business_hours.dart';

void main() {
  test('usable hours become label/value pairs', () {
    final entries = businessHoursEntries(JsonObject({'mon-fri': '7am-6pm', 'sat': '8am-2pm'}));
    expect(entries, hasLength(2));
    expect(entries.first.key, 'mon-fri');
    expect(entries.first.value, '7am-6pm');
  });

  test('null, empty, and blank values yield no entries', () {
    expect(businessHoursEntries(null), isEmpty);
    expect(businessHoursEntries(JsonObject({})), isEmpty);
    expect(businessHoursEntries(JsonObject({'mon': '', 'tue': null})), isEmpty);
  });
}
