import 'package:built_value/json_object.dart';

/// Label/value pairs from `BusinessResponse.businessHours` (free-form JSON).
List<MapEntry<String, String>> businessHoursEntries(JsonObject? hours) {
  if (hours == null) return const [];
  final raw = hours.value;
  if (raw is! Map) return const [];
  final entries = <MapEntry<String, String>>[];
  raw.forEach((key, value) {
    if (value == null) return;
    final text = value is String ? value : value.toString();
    if (text.isEmpty || text == 'null') return;
    entries.add(MapEntry(key.toString(), text));
  });
  return entries;
}
