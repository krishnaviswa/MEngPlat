import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'maps_config.dart';

class MapMarkerTap {
  const MapMarkerTap({required this.point, required this.slug, required this.name});

  final LatLng point;
  final String slug;
  final String name;
}

List<MapMarkerTap> markersForBusinesses(Iterable<BusinessResponse> businesses) {
  return [
    for (final business in businesses)
      if (business.latitude != null && business.longitude != null)
        MapMarkerTap(
          point: LatLng(business.latitude!.toDouble(), business.longitude!.toDouble()),
          slug: business.slug,
          name: business.name,
        ),
  ];
}

/// OpenStreetMap raster map (ADR-006). Tile URL comes from `GET /maps/config`.
class OsmMapView extends StatelessWidget {
  const OsmMapView({
    required this.markers,
    required this.config,
    this.center,
    this.zoom = 12,
    this.height = 280,
    this.onMarkerTap,
    this.mapKey,
    super.key,
  });

  final List<MapMarkerTap> markers;
  final MapsConfig config;
  final LatLng? center;
  final double zoom;
  final double height;
  final ValueChanged<MapMarkerTap>? onMarkerTap;
  final Key? mapKey;

  @override
  Widget build(BuildContext context) {
    final fallback = markers.isNotEmpty ? markers.first.point : const LatLng(13.0827, 80.2707);
    final mapCenter = center ?? fallback;

    final map = FlutterMap(
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: config.tileUrl,
          subdomains: config.subdomains,
          userAgentPackageName: 'com.merchanthub.merchanthub_mobile',
        ),
        MarkerLayer(
          markers: [
            for (final marker in markers)
              Marker(
                point: marker.point,
                width: 40,
                height: 40,
                child: GestureDetector(
                  key: Key('mapPin_${marker.slug}'),
                  onTap: onMarkerTap == null ? null : () => onMarkerTap!(marker),
                  child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
              ),
          ],
        ),
      ],
    );

    final attributed = Stack(
      children: [
        map,
        const Positioned(
          right: 8,
          bottom: 4,
          child: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ),
      ],
    );
    if (height.isFinite) {
      return SizedBox(key: mapKey, height: height, child: attributed);
    }
    return SizedBox.expand(key: mapKey, child: attributed);
  }
}
