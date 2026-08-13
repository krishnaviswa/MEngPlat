import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Device GPS behind a provider so widget tests never hit the geolocator plugin.
abstract class LocationService {
  Future<GeoPoint?> currentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPoint?> currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return GeoPoint(position.latitude, position.longitude);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
