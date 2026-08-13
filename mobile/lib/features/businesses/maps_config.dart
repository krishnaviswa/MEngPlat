import 'package:built_value/json_object.dart';

class MapsConfig {
  const MapsConfig({required this.tileUrl, this.subdomains = const ['a', 'b', 'c']});

  /// OSM.org tiles when `GET /maps/config` is unreachable (ADR-006).
  static const fallback = MapsConfig(
    tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: [],
  );

  final String tileUrl;
  final List<String> subdomains;
}

MapsConfig mapsConfigFromJson(JsonObject? data) {
  if (data == null) return MapsConfig.fallback;
  final raw = data.value;
  if (raw is! Map) return MapsConfig.fallback;
  final tileUrl = raw['tile_url']?.toString();
  if (tileUrl == null || tileUrl.isEmpty) return MapsConfig.fallback;
  final subdomains = tileUrl.contains('{s}') ? const ['a', 'b', 'c'] : const <String>[];
  return MapsConfig(tileUrl: tileUrl, subdomains: subdomains);
}
